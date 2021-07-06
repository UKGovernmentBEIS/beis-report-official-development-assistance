require "rails_helper"

RSpec.describe HasFinancialQuarter do
  TestReport = Struct.new(:financial_quarter, :financial_year) {
    include HasFinancialQuarter
  }

  describe "#own_financial_quarter" do
    it "returns the financial quarter and year as an object" do
      report = TestReport.new(3, 2017)
      expect(report.own_financial_quarter).to eq(FinancialQuarter.new(2017, 3))
    end
  end

  describe "#financial_quarter_and_year" do
    it "returns the formatted financial quarter and year e.g. Q1 2020-2021" do
      report = TestReport.new(1, 2020)
      result = report.financial_quarter_and_year

      expect(result).to eql "FQ1 2020-2021"
    end

    it "returns nil when the report has no financial quarter or year" do
      report = TestReport.new
      result = report.financial_quarter_and_year

      expect(result).to be_nil
    end
  end

  describe "#financial_period" do
    it "returns the period covered by the financial quarter" do
      report = TestReport.new(1, 2020)

      expect(report.financial_period.first).to eq(Date.parse("2020-04-01"))
      expect(report.financial_period.last).to eq(Date.parse("2020-06-30"))
    end
  end
end
