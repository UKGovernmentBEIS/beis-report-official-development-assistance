require "rails_helper"

RSpec.describe Budget do
  describe "relations" do
    it { should belong_to(:parent_activity) }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:budget_type) }
    it { should validate_presence_of(:funding_type) }
    it { should validate_presence_of(:period_start_date) }
    it { should validate_presence_of(:period_end_date) }
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:currency) }

    it { should validate_attribute(:period_start_date).with(:date_within_boundaries) }
    it { should validate_attribute(:period_end_date).with(:date_within_boundaries) }

    describe ".funding_type" do
      it { is_expected.to allow_value("1").for(:funding_type) }
      it { is_expected.not_to allow_value("").for(:funding_type) }
      it { is_expected.not_to allow_value("9999").for(:funding_type) }
    end

    context "when the activity belongs to a delivery partner" do
      it "should validate that the report association exists" do
        activity = build(:activity, organisation: build_stubbed(:delivery_partner_organisation))
        report_for_activity = build_stubbed(:report, organisation: activity.organisation, fund: activity.associated_fund)
        budget = build(:budget, parent_activity: activity, report: nil)

        expect(budget).to be_invalid

        budget.report = report_for_activity

        expect(budget).to be_valid
      end
    end

    context "when the activity belongs to BEIS" do
      it "should validate that the report association exists" do
        activity = build(:activity, organisation: build_stubbed(:beis_organisation))
        budget = build(:budget, parent_activity: activity, report: nil)

        expect(budget).to be_valid
      end
    end
  end

  context "value must be between 0.01 and 99,999,999,999.00 (100 billion minus one)" do
    it "allows the maximum possible value" do
      budget = build(:budget, value: 99_999_999_999.00)
      expect(budget).to be_valid
    end

    it "allows the minimum possible value" do
      budget = build(:budget, value: 0.01)
      expect(budget).to be_valid
    end

    it "allows a value of less than 0" do
      budget = build(:budget, value: -0.01)
      expect(budget).to be_valid
    end

    it "does not allow a value of 0" do
      budget = build(:budget, value: 0)
      expect(budget).to_not be_valid
    end

    it "does not allow a value of more than 99,999,999,999.00" do
      budget = build(:budget, value: 100_000_000_000.00)
      expect(budget).to_not be_valid
    end

    it "allows a value between 1 and 99,999,999,999.00" do
      budget = build(:budget, value: 500_000.00)
      expect(budget).to be_valid
    end
  end

  context "when the period start and period end dates are blank" do
    it "does not perform budget date validation" do
      budget = build(:budget, period_start_date: "", period_end_date: "")

      budget.valid?

      expect(budget.errors[:period_end_date]).not_to include t("activerecord.errors.models.budget.attributes.period_end_date.within_365_days_of_start_date")
    end
  end

  context "when the period start and period end dates are invalid" do
    it "performs budget date validation" do
      budget = build(:budget, period_start_date: Date.today, period_end_date: Date.today + 366.days)

      budget.valid?

      expect(budget.errors[:period_end_date]).to include t("activerecord.errors.models.budget.attributes.period_end_date.within_365_days_of_start_date")
    end
  end
end
