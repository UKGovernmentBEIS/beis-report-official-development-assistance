require "rails_helper"

RSpec.describe Budget do
  let!(:service_owner) { create(:beis_organisation) }

  subject { build(:budget) }

  describe "relations" do
    it { should belong_to(:parent_activity) }
  end

  describe "validations" do
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:financial_year) }

    describe ".budget_type" do
      context "when the parent activity is Newton funded" do
        subject { build(:budget, parent_activity: build(:programme_activity, :newton_funded)) }

        it { is_expected.not_to allow_value(Budget::BUDGET_TYPES["direct_global_challenges_research_fund"]).for(:budget_type) }
        it { is_expected.not_to allow_value(9999).for(:budget_type) }
        it { is_expected.not_to allow_value("").for(:budget_type) }

        it { is_expected.to allow_value(Budget::BUDGET_TYPES["other_official_development_assistance"]).for(:budget_type) }
      end

      context "when the parent activity is GCRF funded" do
        subject { build(:budget, parent_activity: build(:programme_activity, :gcrf_funded)) }

        it { is_expected.not_to allow_value(Budget::BUDGET_TYPES["direct_newton_fund"]).for(:budget_type) }
        it { is_expected.not_to allow_value(9999).for(:budget_type) }
        it { is_expected.not_to allow_value("").for(:budget_type) }

        it { is_expected.to allow_value(Budget::BUDGET_TYPES["other_official_development_assistance"]).for(:budget_type) }
      end
    end

    describe "providing organisation" do
      let(:another_org) { create(:delivery_partner_organisation) }

      context "when the budget_type is a direct type" do
        subject { build(:budget, providing_organisation_id: another_org.id, parent_activity: build(:programme_activity)) }

        it "sets the providing_organisation_id to that of the service_owner" do
          subject.valid?

          expect(subject.providing_organisation_id).to eql(service_owner.id)
        end

        it "discards any input to the _name and _type attributes" do
          subject.providing_organisation_name = "Etc"
          subject.providing_organisation_type = "International ONG"

          subject.valid?

          expect(subject.providing_organisation_name).to be_nil
          expect(subject.providing_organisation_type).to be_nil
        end
      end

      context "when the budget_type is external" do
        subject { build(:budget, budget_type: Budget::BUDGET_TYPES["external"], parent_activity: build(:programme_activity)) }

        it { is_expected.not_to allow_value(nil).for(:providing_organisation_name) }
        it { is_expected.not_to allow_value(nil).for(:providing_organisation_type) }

        it "discards any input to the providing_organisation_id" do
          subject.providing_organisation_id = another_org.id
          subject.valid?

          expect(subject.providing_organisation_id).to be_nil
        end
      end
    end

    context "when the activity belongs to a delivery partner" do
      it "should validate that the report association exists" do
        activity = build(:project_activity, organisation: build_stubbed(:delivery_partner_organisation))
        report_for_activity = build_stubbed(:report, organisation: activity.organisation, fund: activity.associated_fund)
        budget = build(:budget, parent_activity: activity, report: nil)

        expect(budget).to be_invalid

        budget.report = report_for_activity

        expect(budget).to be_valid
      end
    end

    context "when the activity belongs to BEIS" do
      it "should validate that the report association exists" do
        activity = build(:project_activity, organisation: build_stubbed(:beis_organisation))
        budget = build(:budget, parent_activity: activity, report: nil)

        expect(budget).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".direct" do
      it "returns only direct Budgets" do
        newton_fund_budget = create(:budget, :direct_newton)
        gcrf_fund_budget = create(:budget, :direct_gcrf)

        _external_budget = create(:budget, :other_official_development_assistance)

        expect(Budget.direct).to match_array([newton_fund_budget, gcrf_fund_budget])
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

  it "returns an instance of FinancialYear for the financial year" do
    travel_to Date.new(2020, 5, 16) do
      budget = build(:budget, financial_year: Date.today.year)

      expect(budget.financial_year).to be_a(FinancialYear)
      expect(budget.period_start_date).to eq(Date.parse("01-04-2020"))
      expect(budget.period_end_date).to eq(Date.parse("31-03-2021"))
    end
  end
end
