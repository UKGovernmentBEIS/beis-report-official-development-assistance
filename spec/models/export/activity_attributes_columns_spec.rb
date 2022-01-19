RSpec.describe Export::ActivityAttributesColumns do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @activities = create_list(:project_activity, 5)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject { Export::ActivityAttributesColumns.new(activities: @activities, attributes: attributes) }

  context "when the attributes exist on the Activity model" do
    let(:attributes) { [:roda_identifier, :delivery_partner_identifier, :programme_status, :benefitting_region] }

    describe "#headers" do
      it "returns an array of the column headers for the attributes" do
        headers = [
          I18n.t("activerecord.attributes.activity.roda_identifier"),
          I18n.t("activerecord.attributes.activity.delivery_partner_identifier"),
          I18n.t("activerecord.attributes.activity.programme_status"),
          I18n.t("activerecord.attributes.activity.benefitting_region")
        ]
        expect(subject.headers).to match_array(headers)
      end

      it "includes a dynmic (non-active record) attribute header" do
        expect(subject.headers).to include(I18n.t("activerecord.attributes.activity.benefitting_region"))
      end

      describe "ordering" do
        let(:attributes) { [:delivery_partner_identifier, :roda_identifier, :programme_status] }

        it "returns the values in the order they were passed in" do
          headers = [
            I18n.t("activerecord.attributes.activity.delivery_partner_identifier"),
            I18n.t("activerecord.attributes.activity.roda_identifier"),
            I18n.t("activerecord.attributes.activity.programme_status")
          ]
          expect(subject.headers).to match_array(headers)
        end
      end
    end

    describe "#rows" do
      it "returns a hash with activity id keys and an array of the activity values" do
        first_row_activity_presenter = ActivityCsvPresenter.new(@activities.first)
        last_row_activity_presenter = ActivityCsvPresenter.new(@activities.last)

        first_row_values = [
          first_row_activity_presenter.roda_identifier,
          first_row_activity_presenter.delivery_partner_identifier,
          first_row_activity_presenter.programme_status,
          first_row_activity_presenter.benefitting_region
        ]

        last_row_values = [
          last_row_activity_presenter.roda_identifier,
          last_row_activity_presenter.delivery_partner_identifier,
          last_row_activity_presenter.programme_status,
          last_row_activity_presenter.benefitting_region
        ]

        expect(subject.rows.count).to eq 5
        expect(subject.rows.fetch(@activities.first.id)).to match_array(first_row_values)
        expect(subject.rows.fetch(@activities.last.id)).to match_array(last_row_values)
      end

      it "Returns the values in the correct format" do
        last_row_programme_status = ActivityCsvPresenter.new(@activities.last).programme_status

        expect(subject.rows.fetch(@activities.last.id)).to include last_row_programme_status
      end
    end

    context "when there are no activities" do
      subject { Export::ActivityAttributesColumns.new(activities: [], attributes: attributes) }

      describe "#headers" do
        it "returns the headers" do
          headers = [
            I18n.t("activerecord.attributes.activity.roda_identifier"),
            I18n.t("activerecord.attributes.activity.delivery_partner_identifier"),
            I18n.t("activerecord.attributes.activity.programme_status"),
            I18n.t("activerecord.attributes.activity.benefitting_region")
          ]
          expect(subject.headers).to match_array(headers)
        end
      end

      describe "#rows" do
        it "returns an empty array" do
          expect(subject.rows).to eq []
        end
      end
    end
  end

  context "when the attribute does not exist on the Activity model" do
    let(:attributes) { [:not_an_attribute] }

    it "raises an ActiveRecord UnknownAttributeError" do
      expect { subject.headers }.to raise_error ActiveRecord::UnknownAttributeError
      expect { subject.rows }.to raise_error ActiveRecord::UnknownAttributeError
    end
  end

  context "when the attribute is on the ignore list" do
    let(:attributes) { [:roda_identifier, :created_at] }

    it "is ignored" do
      expect(subject.headers).not_to include("Created at")
      expect(subject.rows.first).not_to include @activities.first.created_at
    end
  end
end
