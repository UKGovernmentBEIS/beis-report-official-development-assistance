require "rails_helper"

RSpec.describe Transaction, type: :model do
  let(:activity) { build(:project_activity) }

  it { should have_many(:historical_events) }

  describe ".with_adjustment_details" do
    it "should optionally join the adjustment details table" do
      scope = Adjustment.with_adjustment_details

      expect(scope.to_sql).to include("LEFT OUTER JOIN adjustment_details ON transactions.id = adjustment_details.adjustment_id")
    end
  end

  describe "validations" do
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:financial_year) }

    it { should validate_attribute(:date).with(:date_within_boundaries) }

    context "when the activity belongs to a delivery partner organisation" do
      before { activity.update(organisation: build_stubbed(:delivery_partner_organisation)) }

      it "should validate the presence of report" do
        actual = build_stubbed(:actual, parent_activity: activity, report: nil)
        expect(actual.valid?).to be false
      end
    end

    context "when the activity belongs to BEIS" do
      before { activity.update(organisation: build_stubbed(:beis_organisation)) }

      it "should not validate the presence of report" do
        actual = build_stubbed(:actual, parent_activity: activity, report: nil)
        expect(actual.valid?).to be true
      end
    end

    describe "organisation validation" do
      subject do
        build(:actual,
          receiving_organisation_name: receiving_organisation_name,
          receiving_organisation_type: receiving_organisation_type,
          receiving_organisation_reference: receiving_organisation_reference)
      end

      context "when there is no organisation specified" do
        let(:receiving_organisation_name) { nil }
        let(:receiving_organisation_type) { nil }
        let(:receiving_organisation_reference) { nil }

        it { should be_valid }
      end

      context "when the receiving organisation name is present, but not the type" do
        let(:receiving_organisation_name) { Faker::Company.name }
        let(:receiving_organisation_type) { nil }
        let(:receiving_organisation_reference) { nil }

        it { should be_invalid }
      end

      context "when the receiving organisation type is present, but not the name" do
        let(:receiving_organisation_name) { nil }
        let(:receiving_organisation_type) { "70" }
        let(:receiving_organisation_reference) { nil }

        it { should be_invalid }
      end

      context "when the receiving organisation reference is present, but not the name and type" do
        let(:receiving_organisation_name) { nil }
        let(:receiving_organisation_type) { nil }
        let(:receiving_organisation_reference) { "ABC-123" }

        it { should be_invalid }
      end

      context "when the receiving organisation reference is present, but not the type" do
        let(:receiving_organisation_name) { Faker::Company.name }
        let(:receiving_organisation_type) { nil }
        let(:receiving_organisation_reference) { "ABC-123" }

        it { should be_invalid }
      end

      context "when the receiving organisation reference is present, but not the name" do
        let(:receiving_organisation_name) { nil }
        let(:receiving_organisation_type) { "70" }
        let(:receiving_organisation_reference) { "ABC-123" }

        it { should be_invalid }
      end
    end
  end

  describe "date and financial quarter conversions" do
    let(:actual) { build(:actual, date: nil, financial_quarter: nil, financial_year: nil) }

    context "when the actual has a date" do
      before do
        actual.date = Date.parse("2020-02-18")
      end

      it "is valid" do
        expect(actual).to be_valid
      end

      it "fills in the financial quarter based on the date" do
        actual.valid?
        expect(actual.financial_quarter).to eq(4)
        expect(actual.financial_year).to eq(2019)
      end
    end

    context "when the actual has a financial quarter" do
      before do
        actual.financial_quarter = 4
        actual.financial_year = 2019
      end

      it "is valid" do
        expect(actual).to be_valid
      end

      it "fills in the date based on the financial quarter" do
        actual.valid?
        expect(actual.date).to eq(Date.parse("2020-03-31"))
      end
    end

    context "when the actual has date and a financial quarter" do
      before do
        actual.date = Date.parse("2018-02-18")
        actual.financial_quarter = 4
        actual.financial_year = 2019
      end

      it "is valid" do
        expect(actual).to be_valid
      end

      it "leaves all the values unchanged" do
        actual.valid?
        expect(actual.date).to eq(Date.parse("2018-02-18"))
        expect(actual.financial_quarter).to eq(4)
        expect(actual.financial_year).to eq(2019)
      end
    end

    context "when the actual has no financial quarter" do
      before do
        actual.financial_year = 2019
      end

      it "is not valid" do
        expect(actual).not_to be_valid
        expect(actual.errors[:financial_quarter]).to eq([t("activerecord.errors.models.actual.attributes.financial_quarter.inclusion")])
        expect(actual.errors[:date]).to eq([])
      end

      it "does not assign the date" do
        actual.valid?
        expect(actual.date).to be_nil
      end
    end

    context "when the actual has no financial year" do
      before do
        actual.financial_quarter = 4
      end

      it "is not valid" do
        expect(actual).not_to be_valid
        expect(actual.errors[:financial_year]).to eq([t("activerecord.errors.models.actual.attributes.financial_year.blank")])
        expect(actual.errors[:date]).to eq([])
      end

      it "does not assign the date" do
        actual.valid?
        expect(actual.date).to be_nil
      end
    end
  end

  describe "sanitation" do
    it { should strip_attribute(:receiving_organisation_reference) }
  end

  describe "#value" do
    context "value must be a maximum of 99,999,999,999.00 (100 billion minus one)" do
      it "allows the maximum possible value" do
        actual = build(:actual, parent_activity: activity, value: 99_999_999_999.00)
        expect(actual.valid?).to be true
      end

      it "allows one penny" do
        actual = build(:actual, parent_activity: activity, value: 0.01)
        expect(actual.valid?).to be true
      end

      it "does not allow a value of 0" do
        actual = build(:actual, parent_activity: activity, value: 0)
        expect(actual.valid?).to be false
      end

      it "does not allow a value of more than 99,999,999,999.00" do
        actual = build(:actual, parent_activity: activity, value: 100_000_000_000.00)
        expect(actual.valid?).to be false
      end

      it "allows a value between 1 and 99,999,999,999.00" do
        actual = build(:actual, parent_activity: activity, value: 500_000.00)
        expect(actual.valid?).to be true
      end

      it "allows a negative value" do
        actual = build(:actual, parent_activity: activity, value: -500_000.00)
        expect(actual.valid?).to be true
      end
    end
  end
end
