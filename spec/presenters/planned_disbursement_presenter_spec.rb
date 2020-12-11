require "rails_helper"

RSpec.describe PlannedDisbursementPresenter do
  let(:planned_disbursement) { build_stubbed(:planned_disbursement) }

  describe "#value" do
    it "returns the value to two decimal places with a currency symbol" do
      expect(described_class.new(planned_disbursement).value).to eq("£100,000.00")
    end
  end

  describe "#financial_quarter_and_year" do
    it "returns the formatted financial quarter and year e.g. Q1 2020-2021" do
      planned_disbursement = build(:planned_disbursement, financial_quarter: 1, financial_year: 2020)
      result = described_class.new(planned_disbursement).financial_quarter_and_year

      expect(result).to eql "Q1 2020-2021"
    end

    it "returns nil when the planned_disbursement has no financial quarter or year" do
      planned_disbursement = build(:planned_disbursement, financial_quarter: nil, financial_year: nil)
      result = described_class.new(planned_disbursement).financial_quarter_and_year

      expect(result).to be_nil
    end
  end
end
