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

  describe "#to_hash" do
    it "returns parameters suitable for querying ActiveRecord models" do
      quarter = FinancialQuarter.new(2017, 3)
      expect(quarter.to_hash).to eq(financial_quarter: 3, financial_year: 2017)
    end
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

  describe "#preceding" do
    it "returns the preceding N financial quarters" do
      quarter = FinancialQuarter.new(2017, 2)
      expect(quarter.preceding(7)).to eq([
        FinancialQuarter.new(2015, 3),
        FinancialQuarter.new(2015, 4),
        FinancialQuarter.new(2016, 1),
        FinancialQuarter.new(2016, 2),
        FinancialQuarter.new(2016, 3),
        FinancialQuarter.new(2016, 4),
        FinancialQuarter.new(2017, 1)
      ])
    end
  end

  describe "#following" do
    it "returns the following N financial quarters" do
      quarter = FinancialQuarter.new(2017, 2)
      expect(quarter.following(7)).to eq([
        FinancialQuarter.new(2017, 3),
        FinancialQuarter.new(2017, 4),
        FinancialQuarter.new(2018, 1),
        FinancialQuarter.new(2018, 2),
        FinancialQuarter.new(2018, 3),
        FinancialQuarter.new(2018, 4),
        FinancialQuarter.new(2019, 1)
      ])
    end
  end

  describe ".from_date" do
    it "returns Q1 for dates in April, May and June" do
      april_date = Date.new(2020, 4, 1)
      may_date = Date.new(2020, 5, 16)
      june_date = Date.new(2020, 6, 19)

      expect(FinancialQuarter.for_date(april_date).to_s).to eq("FQ1 2020-2021")
      expect(FinancialQuarter.for_date(may_date).to_s).to eq("FQ1 2020-2021")
      expect(FinancialQuarter.for_date(june_date).to_s).to eq("FQ1 2020-2021")
    end

    it "returns Q2 for dates in July, August and September" do
      july_date = Date.new(2020, 7, 2)
      august_date = Date.new(2020, 8, 16)
      september_date = Date.new(2020, 9, 23)

      expect(FinancialQuarter.for_date(july_date).to_s).to eq("FQ2 2020-2021")
      expect(FinancialQuarter.for_date(august_date).to_s).to eq("FQ2 2020-2021")
      expect(FinancialQuarter.for_date(september_date).to_s).to eq("FQ2 2020-2021")
    end

    it "returns Q3 for dates in October, November and December" do
      october_date = Date.new(2020, 10, 31)
      november_date = Date.new(2020, 11, 5)
      december_date = Date.new(2020, 12, 25)

      expect(FinancialQuarter.for_date(october_date).to_s).to eq("FQ3 2020-2021")
      expect(FinancialQuarter.for_date(november_date).to_s).to eq("FQ3 2020-2021")
      expect(FinancialQuarter.for_date(december_date).to_s).to eq("FQ3 2020-2021")
    end

    it "returns Q4 for dates in January, February and March" do
      january_date = Date.new(2021, 1, 7)
      february_date = Date.new(2021, 2, 15)
      march_date = Date.new(2021, 3, 27)

      expect(FinancialQuarter.for_date(january_date).to_s).to eq("FQ4 2020-2021")
      expect(FinancialQuarter.for_date(february_date).to_s).to eq("FQ4 2020-2021")
      expect(FinancialQuarter.for_date(march_date).to_s).to eq("FQ4 2020-2021")
    end
  end

  describe "#==" do
    it "is true for quarters with the same year and the same quarter" do
      expect(FinancialQuarter.new(2020, 3)).to eq(FinancialQuarter.new(2020, 3))
    end
  end

  describe "#<=>" do
    let(:oldest_quarter) { FinancialQuarter.new(2019, 3) }
    let(:middle_quarter) { FinancialQuarter.new(2019, 4) }
    let(:latest_quarter) { FinancialQuarter.new(2020, 1) }

    it "compares quarters chronologically" do
      quarters = [middle_quarter, latest_quarter, oldest_quarter]

      expect(quarters.sort).to match_array([oldest_quarter, middle_quarter, latest_quarter])
    end
  end
end
