require "rails_helper"

RSpec.describe Report, type: :model do
  describe "validations" do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:state) }
    it { should have_readonly_attribute(:financial_quarter) }
    it { should have_readonly_attribute(:financial_year) }
  end

  describe "associations" do
    it { should belong_to(:fund).class_name("Activity") }
    it { should belong_to(:organisation) }
  end

  it "sets the financial_quarter and financial_year when created" do
    travel_to(Date.parse("01-04-2020")) do
      report = Report.new

      expect(report.financial_quarter).to eql 1
    end
  end

  it "does not allow an association to an Activity that is not level = fund" do
    programme = create(:programme_activity)
    report = build(:report, fund: programme)
    expect(report).not_to be_valid
    expect(report.errors[:fund]).to include t("activerecord.errors.models.report.attributes.fund.level")
  end

  it "does not allow more than one Report for the same Fund and Organisation combination" do
    organisation = create(:delivery_partner_organisation)
    fund = create(:fund_activity)
    _existing_report = create(:report, organisation: organisation, fund: fund)

    new_report = build(:report, organisation: organisation, fund: fund)
    expect(new_report).not_to be_valid
  end

  it "does not allow a Deadline which is in the past" do
    report = build(:report, deadline: Date.yesterday)
    expect(report).not_to be_valid
  end

  describe "#financial_quarter" do
    context "when in the first quarter of the financial year - April to March" do
      it "sets the financial quarter to 1" do
        ["1 April 2020", "30 June 2020"].each do |date|
          travel_to(Date.parse(date)) do
            report = Report.new
            expect(report.financial_quarter).to eql 1
          end
        end
      end
    end

    context "when in the second quarter of the financial year - May to July" do
      it "sets the financial quarter to 2" do
        ["1 July 2020", "30 September 2020"].each do |date|
          travel_to(Date.parse(date)) do
            report = Report.new
            expect(report.financial_quarter).to eql 2
          end
        end
      end
    end

    context "when in the third quarter of the financial year - October to December" do
      it "sets the financial quarter to 3" do
        ["1 October 2020", "31 December 2020"].each do |date|
          travel_to(Date.parse(date)) do
            report = Report.new
            expect(report.financial_quarter).to eql 3
          end
        end
      end
    end

    context "when in the fourth quarter of the financial year - January to March" do
      it "sets the financial quarter to 4" do
        ["1 January 2020", "31 March 2020"].each do |date|
          travel_to(Date.parse(date)) do
            report = Report.new
            expect(report.financial_quarter).to eql 4
          end
        end
      end
    end
  end

  describe "#financial_year" do
    context "when in the first, second or third quarter of the 2020-2021 financial year" do
      it "sets the financial year to 2020" do
        travel_to(Date.parse("1 May 2020")) do
          report = Report.new
          expect(report.financial_year).to eql 2020
        end

        travel_to(Date.parse("1 September 2020")) do
          report = Report.new
          expect(report.financial_year).to eql 2020
        end

        travel_to(Date.parse("1 November 2020")) do
          report = Report.new
          expect(report.financial_year).to eql 2020
        end
      end
    end

    context "when in the fourth quarter of the 2020-2021 financial year" do
      it "sets the financial year to 2020" do
        travel_to(Date.parse("1 February 2021")) do
          report = Report.new
          expect(report.financial_year).to eql 2020
        end
      end
    end
  end

  describe "#next_four_financial_quarters" do
    context "when in Q1 2020" do
      it "returns an array with the next four financial quarters" do
        travel_to(Date.parse("1 April 2020")) do
          report = create(:report)

          expect(report.next_four_financial_quarters).to eq ["Q2 2020", "Q3 2020", "Q4 2020", "Q1 2021"]
        end
      end
    end

    context "when in Q2 2020" do
      it "returns an array with the next four financial quarters" do
        travel_to(Date.parse("1 July 2020")) do
          report = create(:report)

          expect(report.next_four_financial_quarters).to eq ["Q3 2020", "Q4 2020", "Q1 2021", "Q2 2021"]
        end
      end
    end

    context "when in Q3 2020" do
      it "returns an array with the next four financial quarters" do
        travel_to(Date.parse("1 October 2020")) do
          report = create(:report)

          expect(report.next_four_financial_quarters).to eq ["Q4 2020", "Q1 2021", "Q2 2021", "Q3 2021"]
        end
      end
    end

    context "when in Q4 2020" do
      it "returns an array with the next four financial quarters" do
        travel_to(Date.parse("1 January 2021")) do
          report = create(:report)

          expect(report.next_four_financial_quarters).to eq ["Q1 2021", "Q2 2021", "Q3 2021", "Q4 2021"]
        end
      end
    end
  end
end
