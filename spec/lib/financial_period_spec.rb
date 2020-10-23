require "rails_helper"

RSpec.describe FinancialPeriod do
  describe "#quarter_from_date" do
    it "returns the correct financial quarter for a given date" do
      dates_in_quarter_one = ["2020-04-01", "2020-05-12", "2020-06-06"]
      dates_in_quarter_one.each do |date|
        expect(FinancialPeriod.quarter_from_date(Date.parse(date))).to eql "1"
      end

      dates_in_quarter_two = ["2020-07-09", "2020-08-21", "2020-09-03"]
      dates_in_quarter_two.each do |date|
        expect(FinancialPeriod.quarter_from_date(Date.parse(date))).to eql "2"
      end

      dates_in_quarter_three = ["2020-10-26", "2020-11-06", "2020-12-24"]
      dates_in_quarter_three.each do |date|
        expect(FinancialPeriod.quarter_from_date(Date.parse(date))).to eql "3"
      end

      dates_in_quarter_four = ["2020-01-01", "2020-02-29", "2020-03-23"]
      dates_in_quarter_four.each do |date|
        expect(FinancialPeriod.quarter_from_date(Date.parse(date))).to eql "4"
      end
    end
  end

  describe "#year_from_date" do
    context "when the date is in quarter 1,2 and 3" do
      it "returns the correct financial year" do
        date_in_quarter_one = Date.parse("2020-04-02")
        expect(FinancialPeriod.year_from_date(date_in_quarter_one)).to eql "2020"

        date_in_quarter_two = Date.parse("2020-09-10")
        expect(FinancialPeriod.year_from_date(date_in_quarter_two)).to eql "2020"

        date_in_quarter_three = Date.parse("2020-11-24")
        expect(FinancialPeriod.year_from_date(date_in_quarter_three)).to eql "2020"
      end
    end

    context "when the date is in quarter 4" do
      it "returns the correct financial year" do
        date_in_quarter_four = Date.parse("2020-02-21")
        expect(FinancialPeriod.year_from_date(date_in_quarter_four)).to eql "2019"
      end
    end
  end
end
