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
    let(:attributes) { [:roda_identifier, :delivery_partner_identifier] }

    describe "#headers" do
      it "returns an array of the column headers for the attributes" do
        headers = [
          I18n.t("activerecord.attributes.activity.roda_identifier"),
          I18n.t("activerecord.attributes.activity.delivery_partner_identifier"),
        ]
        expect(subject.headers).to match_array(headers)
      end

      describe "ordering" do
        let(:attributes) { [:delivery_partner_identifier, :roda_identifier] }

        it "returns the values in the order they were passed in" do
          headers = [
            I18n.t("activerecord.attributes.activity.delivery_partner_identifier"),
            I18n.t("activerecord.attributes.activity.roda_identifier"),
          ]
          expect(subject.headers).to match_array(headers)
        end
      end
    end

    describe "#rows" do
      it "returns a hash with activity id keys and an array of the activity values" do
        first_row_values = [
          @activities.first.roda_identifier,
          @activities.first.delivery_partner_identifier,
        ]

        last_row_values = [
          @activities.last.roda_identifier,
          @activities.last.delivery_partner_identifier,
        ]

        expect(subject.rows.count).to eq 5
        expect(subject.rows.fetch(@activities.first.id)).to match_array(first_row_values)
        expect(subject.rows.fetch(@activities.last.id)).to match_array(last_row_values)
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
