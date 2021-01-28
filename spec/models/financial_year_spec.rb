require "rails_helper"

RSpec.describe FinancialYear do
  it "initializes successfully" do
    year = FinancialYear.new("2020")

    expect(year.start_year).to eq(2020)
    expect(year.end_year).to eq(2021)

    expect(year.start_date).to eq(Date.parse("2020-04-01"))
    expect(year.end_date).to eq(Date.parse("2021-03-31"))
    expect(year.to_i).to eq(2020)
    expect(year.to_s).to eq("2020-2021")
  end

  it "raises an error if the year is invalid" do
    expect { FinancialYear.new("sdfdsfsdfsfs") }.to raise_error(FinancialYear::InvalidYear)
  end

  it "returns quarters" do
    year = FinancialYear.new("2020")

    expect(year.quarters.count).to eq(4)
    expect(year.quarters.map { |q| q.to_s }).to eq(["Q1 2020-2021", "Q2 2020-2021", "Q3 2020-2021", "Q4 2020-2021"])
  end

  describe ".for_date" do
    it "returns the previous calendar year if the month is January, February or March" do
      (1..3).each do |month|
        date = Date.parse("2020-#{month}-01")
        expect(FinancialYear.for_date(date).to_i).to eq(2019)
      end
    end

    it "returns the current calendar year if the month is April or later" do
      (4..12).each do |month|
        date = Date.parse("2020-#{month}-01")
        expect(FinancialYear.for_date(date).to_i).to eq(2020)
      end
    end
  end
end
