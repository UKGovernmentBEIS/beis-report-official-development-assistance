require "rails_helper"

RSpec.describe IngestCsv do
  describe "#call" do
    context "with a CSV file which references identifiers that already exist in RODA" do
      before do
        create(:fund_activity, title: "Newton fund") do |fund|
          ["EXAMPLE_01", "EXAMPLE_02", "EXAMPLE_03", "EXAMPLE_XX"].each do |identifier|
            create(:programme_activity, delivery_partner_identifier: identifier, parent: fund, updated_at: 1.month.ago)
          end
        end
      end

      it "updates those activities" do
        csv_file = "#{Rails.root}/spec/fixtures/csv/additional_fields.csv"

        IngestCsv.new(csv_file).call

        expect(Activity.programme.where(updated_at: Date.today..).count).to eql 3
      end
    end

    context "with a CSV file which contains a column which references a parent activity" do
      before do
        create(:fund_activity, roda_identifier_fragment: "GCRF") do |fund|
          create(:programme_activity, parent: fund, roda_identifier_fragment: "RFSBA") do |programme|
            create(:project_activity, parent: programme, roda_identifier_fragment: "R5")
          end

          create(:programme_activity, parent: fund, roda_identifier_fragment: "RFFLAIR") do |programme|
            create(:project_activity, parent: programme, roda_identifier_fragment: "FLRR12020")
          end
        end
      end

      it "creates new activities" do
        csv_file = "#{Rails.root}/spec/fixtures/csv/new_activities.csv"

        expect { IngestCsv.new(csv_file).call }
          .to change { Activity.third_party_project.count }
          .by(2)
      end

      it "updates any existing activities" do
        parent = Activity.project.find_by(roda_identifier_fragment: "FLRR12020")
        third_party_project = create(:third_party_project_activity,
          parent: parent,
          delivery_partner_identifier: "EXAMPLE_02",
          title: "OVERWRITE ME")

        csv_file = "#{Rails.root}/spec/fixtures/csv/existing_activity.csv"

        expect { IngestCsv.new(csv_file).call }
          .not_to change { Activity.third_party_project.count }

        expect(third_party_project.reload.title)
          .to eql "Isolation and redesign of single-celled examples"
      end
    end
  end
end
