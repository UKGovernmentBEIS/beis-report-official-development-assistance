require "rails_helper"

RSpec.describe Report, type: :model do
  describe "validations" do
    it { should validate_presence_of(:state) }
    it { should have_readonly_attribute(:financial_quarter) }
    it { should have_readonly_attribute(:financial_year) }
  end

  describe "associations" do
    it { should belong_to(:fund).class_name("Activity") }
    it { should belong_to(:organisation) }
    it { should have_many(:historical_events) }
    it { should have_many(:new_activities).class_name("Activity") }
    it { should have_many(:refunds) }
  end

  describe ".editable_for_activity" do
    let!(:organisation) { create(:delivery_partner_organisation) }
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

  describe "#reportable_activities" do
    let(:report) { build(:report, financial_quarter: 1, financial_year: 2020) }
    let(:active_relation) { double("active_relation") }
    let(:query) { double("query", with_roda_identifier: active_relation) }
    let(:finder) { instance_double(Activity::ProjectsForReportFinder, call: query) }

    before do
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder)
    end

    it "appends the `with_roda_identifier` scope" do
      report.reportable_activities

      expect(query).to have_received(:with_roda_identifier)
    end

    it "returns the active_relation" do
      expect(report.reportable_activities).to eq(active_relation)
    end
  end

  describe "#forecasts_for_reportable_activities" do
    let(:report) { build(:report) }
    let(:reportable_activities) { build_stubbed_list(:project_activity, 5) }
    let(:active_relation) { double("active_relation") }
    let(:latest_values) { double("latest_values", where: active_relation) }
    let(:overview) { instance_double(ForecastOverview, latest_values: latest_values) }

    before do
      allow(report).to receive(:reportable_activities).and_return(reportable_activities)
      allow(ForecastOverview).to receive(:new).and_return(overview)
    end

    it "passes the correct reportable activities to the forecast overview" do
      report.forecasts_for_reportable_activities

      expect(ForecastOverview).to have_received(:new).with(reportable_activities.map(&:id))
    end

    it "passes the report to the latest_values relation" do
      report.forecasts_for_reportable_activities

      expect(latest_values).to have_received(:where).with(report: report)
    end

    it "returns an active relation" do
      expect(report.forecasts_for_reportable_activities).to eq(active_relation)
    end
  end

  describe "#summed_forecasts" do
    let(:report) { build(:report) }

    before do
      expect(report).to receive(:forecasts_for_reportable_activities) {
        [
          double("forecast", value: 50_000),
          double("forecast", value: 25_000),
          double("forecast", value: 25_000),
        ]
      }
    end

    it "sums the forecasts" do
      expect(report.summed_forecasts_for_reportable_activities.to_i).to eq(100_000)
    end
  end

  describe "activities_updated" do
    it "only returns activities that have been updated during the reporting period" do
      fund = create(:fund_activity)

      report = create(:report, fund: fund)

      programme = create(:programme_activity, parent: fund)
      project_updated_in_report = create(:project_activity, parent: programme)
      other_project_updated_in_report = create(:project_activity, parent: programme)
      third_party_project_updated_in_report = create(:third_party_project_activity, parent: project_updated_in_report)

      _project_not_updated_in_report = create(:project_activity, parent: programme)
      _third_party_project_not_updated_in_report = create(:third_party_project_activity, parent: project_updated_in_report)

      create(:historical_event, activity: project_updated_in_report, report: report)
      create_list(:historical_event, 2, activity: other_project_updated_in_report, report: report)
      create(:historical_event, activity: third_party_project_updated_in_report, report: report)

      expect(report.activities_updated).to match_array([
        project_updated_in_report,
        other_project_updated_in_report,
        third_party_project_updated_in_report,
      ])
    end

    it "handles the case where there are orphaned HistoricalEvents, after an activity has been deleted" do
      historical_event = create(:historical_event)
      report = historical_event.report

      historical_event.activity.destroy

      expect(report.activities_updated.count).to eql 0
    end
  end

  describe "#editable?" do
    all_report_states = Report.states.keys
    editable_states = Report::EDITABLE_STATES
    readonly_states = all_report_states - editable_states

    editable_states.each do |state|
      it "is false when the report is #{state}", state: state do |example|
        report = Report.new(state: example.metadata[:state])

        expect(report.editable?).to be_truthy
      end
    end

    readonly_states.each do |state|
      it "is true when the report is #{state}", state: state do |example|
        report = Report.new(state: example.metadata[:state])

        expect(report.editable?).to be_falsey
      end
    end
  end

  describe "#summed_transactions" do
    it "sums all of the transactions belonging to a report" do
      report = create(:report)

      create(:transaction, report: report, value: 50)
      create(:transaction, report: report, value: 75)
      create(:transaction, report: report, value: 100)

      expect(report.summed_transactions).to eq(225)
    end
  end

  describe "#summed_refunds" do
    it "sums all of the refunds belonging to a report" do
      report = create(:report)

      create(:refund, report: report, value: 25)
      create(:refund, report: report, value: 75)
      create(:refund, report: report, value: 100)

      expect(report.summed_refunds).to eq(200)
    end
  end
end
