require "rails_helper"

RSpec.describe FinancialQuarter do
  it "returns the correct start and end dates for Q1" do
    financial_quarter = FinancialQuarter.new(2020, 1)

    expect(financial_quarter.start_date).to eq(Date.parse("2020-04-01"))
    expect(financial_quarter.end_date).to eq(Date.parse("2020-06-30"))
  end

  it "returns the correct start and end dates for Q2" do
    financial_quarter = FinancialQuarter.new(2020, 2)

    expect(financial_quarter.start_date).to eq(Date.parse("2020-07-01"))
    expect(financial_quarter.end_date).to eq(Date.parse("2020-09-30"))
  end

  it "returns the correct start and end dates for Q3" do
    financial_quarter = FinancialQuarter.new(2020, 3)

    expect(financial_quarter.start_date).to eq(Date.parse("2020-10-01"))
    expect(financial_quarter.end_date).to eq(Date.parse("2020-12-31"))
  end

  it "returns the correct start and end dates for Q4" do
    financial_quarter = FinancialQuarter.new(2020, 4)

    expect(financial_quarter.start_date).to eq(Date.parse("2021-01-01"))
    expect(financial_quarter.end_date).to eq(Date.parse("2021-03-31"))
  end

  describe "#pred" do
    it "returns the following quarter" do
      quarter = FinancialQuarter.new(2020, 2)
      expect(quarter.pred).to eq(FinancialQuarter.new(2020, 1))
    end

    it "returns a quarter in the pred year" do
      quarter = FinancialQuarter.new(2020, 1)
      expect(quarter.pred).to eq(FinancialQuarter.new(2019, 4))
    end
  end

  describe "#succ" do
    it "returns the following quarter" do
      quarter = FinancialQuarter.new(2020, 1)
      expect(quarter.succ).to eq(FinancialQuarter.new(2020, 2))
    end

    it "returns a quarter in the following year" do
      quarter = FinancialQuarter.new(2020, 4)
      expect(quarter.succ).to eq(FinancialQuarter.new(2021, 1))
    end
  end

  describe ".from_date" do
    it "returns Q1 for dates in April, May and June" do
      april_date = Date.new(2020, 4, 1)
      may_date = Date.new(2020, 5, 16)
      june_date = Date.new(2020, 6, 19)

      expect(FinancialQuarter.for_date(april_date).to_s).to eq("Q1 2020-2021")
      expect(FinancialQuarter.for_date(may_date).to_s).to eq("Q1 2020-2021")
      expect(FinancialQuarter.for_date(june_date).to_s).to eq("Q1 2020-2021")
    end

    it "returns Q2 for dates in July, August and September" do
      july_date = Date.new(2020, 7, 2)
      august_date = Date.new(2020, 8, 16)
      september_date = Date.new(2020, 9, 23)

      expect(FinancialQuarter.for_date(july_date).to_s).to eq("Q2 2020-2021")
      expect(FinancialQuarter.for_date(august_date).to_s).to eq("Q2 2020-2021")
      expect(FinancialQuarter.for_date(september_date).to_s).to eq("Q2 2020-2021")
    end

    it "returns Q3 for dates in October, November and December" do
      october_date = Date.new(2020, 10, 31)
      november_date = Date.new(2020, 11, 5)
      december_date = Date.new(2020, 12, 25)

      expect(FinancialQuarter.for_date(october_date).to_s).to eq("Q3 2020-2021")
      expect(FinancialQuarter.for_date(november_date).to_s).to eq("Q3 2020-2021")
      expect(FinancialQuarter.for_date(december_date).to_s).to eq("Q3 2020-2021")
    end

    it "returns Q4 for dates in January, February and March" do
      january_date = Date.new(2021, 1, 7)
      february_date = Date.new(2021, 2, 15)
      march_date = Date.new(2021, 3, 27)

      expect(FinancialQuarter.for_date(january_date).to_s).to eq("Q4 2020-2021")
      expect(FinancialQuarter.for_date(february_date).to_s).to eq("Q4 2020-2021")
      expect(FinancialQuarter.for_date(march_date).to_s).to eq("Q4 2020-2021")
    end
  end
end
