require "rails_helper"

RSpec.describe Report, type: :model do
  describe "validations" do
    it { should validate_presence_of(:description).on([:edit, :activate]) }
    it { should validate_presence_of(:state) }
    it { should have_readonly_attribute(:financial_quarter) }
    it { should have_readonly_attribute(:financial_year) }
  end

  describe "associations" do
    it { should belong_to(:fund).class_name("Activity") }
    it { should belong_to(:organisation) }
  end

  describe ".editable_for_activity" do
    let!(:organisation) { create(:organisation) }
    let!(:project) { create(:project_activity, organisation: organisation) }
    let!(:project_in_another_fund) { create(:project_activity, organisation: organisation) }

    let! :approved_report do
      create(:report, fund: project.associated_fund, organisation: organisation, state: :approved)
    end

    let! :report_for_another_fund do
      create(:report, fund: project_in_another_fund.associated_fund, organisation: organisation, state: :active)
    end

    context "when there is an active report" do
      let! :active_report do
        create(:report, fund: project.associated_fund, organisation: organisation, state: :active)
      end

      it "returns the editable report for the activity's fund" do
        expect(Report.editable_for_activity(project)).to eq(active_report)
      end
    end

    context "when there is a report awaiting changes" do
      let! :report_awaiting_changes do
        create(:report, fund: project.associated_fund, organisation: organisation, state: :awaiting_changes)
      end

      it "returns the editable report for the activity's fund" do
        expect(Report.editable_for_activity(project)).to eq(report_awaiting_changes)
      end
    end

    context "when there is no editable report" do
      it "returns nothing" do
        expect(Report.editable_for_activity(project)).to be_nil
      end
    end
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

  it "allows a deadline which is in the past by default" do
    report = build(:report, deadline: Date.yesterday)
    expect(report).to be_valid
  end

  context "when editing the report details i.e. in the `edit` validation context" do
    it "does not allow a deadline which is in the past" do
      report = build(:report, deadline: Date.yesterday)
      expect(report.valid?(:edit)).to eq false
    end
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

  describe "reportable_activities" do
    let!(:report) { create(:report) }
    let!(:programme) { create(:programme_activity, parent: report.fund, organisation: report.organisation) }
    let!(:project_a) { create(:project_activity, parent: programme, organisation: report.organisation) }
    let!(:project_b) { create(:project_activity, parent: programme, organisation: report.organisation) }
    let!(:third_party_project) { create(:third_party_project_activity, parent: project_b, organisation: report.organisation) }
    let!(:cancelled_project) { create(:project_activity, parent: programme, organisation: report.organisation, programme_status: "cancelled") }
    let!(:project_in_another_fund) { create(:project_activity, organisation: report.organisation) }

    it "returns the level C and D activities belonging to the report's fund and organisation" do
      expect(report.reportable_activities).to include(project_a)
      expect(report.reportable_activities).to include(project_b)
      expect(report.reportable_activities).to include(third_party_project)

      expect(report.reportable_activities).not_to include(report.fund)
      expect(report.reportable_activities).not_to include(programme)
      expect(report.reportable_activities).not_to include(project_in_another_fund)
      expect(report.reportable_activities).not_to include(cancelled_project)
    end
  end
end
