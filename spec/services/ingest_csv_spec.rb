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

        expect(Activity.where(updated_at: Date.today..).count).to eql 3
      end
    end
  end
end
