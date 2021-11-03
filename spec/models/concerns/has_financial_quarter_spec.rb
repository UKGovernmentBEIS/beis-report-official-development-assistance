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

  describe "later_period_than?(other)" do
    let(:q2_2021) { TestReport.new(2, 2021) }
    let(:q3_2021) { TestReport.new(3, 2021) }

    it "returns TRUE when the period being compared is earlier" do
      expect(q3_2021).to be_later_period_than(q2_2021)
    end

    it "returns FALSE when the period being compared is later" do
      expect(q2_2021).not_to be_later_period_than(q3_2021)
    end

    it "returns FALSE when the period being compared is the same" do
      expect(q3_2021).not_to be_later_period_than(q3_2021)
    end

    it "returns TRUE when the object compared is missing" do
      expect(q3_2021).to be_later_period_than(nil)
    end

    it "returns TRUE when the period being compared is blank or missing" do
      expect(q3_2021).to be_later_period_than(TestReport.new(nil, nil))
    end
  end

  describe "#first_day_of_financial_period" do
    it "returns the first day of the financial period" do
      report = TestReport.new(4, 2021)

      expect(report.first_day_of_financial_period).to eq(Date.parse("2022-01-01"))
    end
  end
end
