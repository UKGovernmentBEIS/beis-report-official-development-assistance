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

  describe "#current_financial_quarter" do
    context "when the month is in the first quarter" do
      it "returns the financial quarter based on the date today" do
        travel_to Date.parse("2019-04-01") do
          expect(FinancialPeriod.current_financial_quarter).to eql "1"
        end
      end
    end

    context "when the month is in the second quarter" do
      it "returns the financial quarter based on the date today" do
        travel_to Date.parse("2019-07-01") do
          expect(FinancialPeriod.current_financial_quarter).to eql "2"
        end
      end
    end

    context "when the month is in the third quarter" do
      it "returns the financial quarter based on the date today" do
        travel_to Date.parse("2019-10-01") do
          expect(FinancialPeriod.current_financial_quarter).to eql "3"
        end
      end
    end

    context "when the month is in the fourth quarter" do
      it "returns the financial quarter based on the date today" do
        travel_to Date.parse("2020-01-01") do
          expect(FinancialPeriod.current_financial_quarter).to eql "4"
        end
      end
    end
  end

  describe "#current_financial_year" do
    context "when it is the first, second or third financial quarter" do
      it "returns the current four digit year as a string" do
        dates = ["2019-05-03", "2019-08-15", "2019-10-03"]
        dates.each do |date|
          travel_to Date.parse(date) do
            expect(FinancialPeriod.current_financial_year).to eql "2019"
          end
        end
      end
    end

    context "when it is the fourth financial quarter" do
      it "returns the previous four digit year as a string" do
        travel_to Date.parse("2020-02-09") do
          expect(FinancialPeriod.current_financial_year).to eql "2019"
        end
      end
    end
  end

  describe "#next_ten_years" do
    it "returns the list of the next ten financial years including the current financial year" do
      dates = ["2019-05-03", "2019-08-15", "2019-10-03", "2020-02-09"]
      dates.each do |date|
        travel_to Date.parse(date) do
          expect(FinancialPeriod.next_ten_years).to eql [2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026, 2027, 2028]
        end
      end
    end
  end

  describe "#start_date_from_quarter_and_year" do
    it "returns the date of the first day of a quarter" do
      expect(FinancialPeriod.start_date_from_quarter_and_year("1", "2020")).to eq "2020-04-01".to_date
    end
  end

  describe "#end_date_from_financial_quarter_and_year" do
    it "returns the date of the last day of a quarter" do
      expect(FinancialPeriod.end_date_from_quarter_and_year("1", "2020")).to eq "2020-06-30".to_date
    end
  end
end
