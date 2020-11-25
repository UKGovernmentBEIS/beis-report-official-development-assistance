require "rails_helper"
require "csv"

RSpec.describe ExportActivityToCsv do
  let(:project) { create(:project_activity, :with_report) }
  let(:report) { Report.find_by(fund: project.associated_fund, organisation: project.organisation) }
  let!(:comment) { create(:comment, report: report, activity: project) }

  describe "#call" do
    it "creates a CSV line representation of the Activity" do
      activity_presenter = ActivityCsvPresenter.new(project)
      export_service = ExportActivityToCsv.new(activity: project, report: report)
      result = export_service.call
      next_four_quarter_totals = export_service.next_four_quarter_forecasts

      expect(result).to eq([
        activity_presenter.funding_organisation_name,
        activity_presenter.transparency_identifier,
        activity_presenter.delivery_partner_identifier,
        activity_presenter.roda_identifier,
        activity_presenter.beis_id,
        activity_presenter.level,
        activity_presenter.title,
        activity_presenter.description,
        activity_presenter.objectives,
        activity_presenter.recipient_region,
        activity_presenter.recipient_country,
        activity_presenter.intended_beneficiaries,
        activity_presenter.programme_status,
        activity_presenter.planned_start_date,
        activity_presenter.actual_start_date,
        activity_presenter.planned_end_date,
        activity_presenter.actual_end_date,
        activity_presenter.call_open_date,
        activity_presenter.call_close_date,
        activity_presenter.total_applications,
        activity_presenter.total_awards,
        activity_presenter.sector_with_code,
        activity_presenter.aid_type_with_code,
        activity_presenter.tied_status_with_code,
        activity_presenter.finance_with_code,
        activity_presenter.flow_with_code,
        activity_presenter.gdi,
        activity_presenter.collaboration_type,
        activity_presenter.covid19_related,
        activity_presenter.policy_marker_gender,
        activity_presenter.policy_marker_climate_change_adaptation,
        activity_presenter.policy_marker_climate_change_mitigation,
        activity_presenter.policy_marker_biodiversity,
        activity_presenter.policy_marker_desertification,
        activity_presenter.policy_marker_disability,
        activity_presenter.policy_marker_disaster_risk_reduction,
        activity_presenter.policy_marker_nutrition,
        activity_presenter.oda_eligibility,
        activity_presenter.oda_eligibility_lead,
        activity_presenter.forecasted_total_for_report_financial_quarter(report: report),
        activity_presenter.actual_total_for_report_financial_quarter(report: report),
        activity_presenter.variance_for_report_financial_quarter(report: report),
        activity_presenter.comment_for_report(report_id: report.id).comment,
        activity_presenter.link_to_roda,
      ].concat(next_four_quarter_totals).to_csv)
    end

    it "includes the BEIS id if there is one" do
      project.update(beis_id: "GCRF_AHRC_NS_AH1001")
      activity_presenter = ActivityCsvPresenter.new(project)
      export_service = ExportActivityToCsv.new(activity: project, report: report)
      result = export_service.call

      expect(result).to include activity_presenter.beis_id
    end
  end

  describe "#next_four_quarter_forecasts" do
    it "gets the forecasted total for the date ranges of the next four quarters" do
      _disbursement_1 = create(:planned_disbursement, parent_activity: project, period_start_date: 3.months.from_now, value: 1000, financial_quarter: FinancialPeriod.quarter_from_date(3.months.from_now), financial_year: FinancialPeriod.year_from_date(3.months.from_now))
      _disbursement_2 = create(:planned_disbursement, parent_activity: project, period_start_date: 9.months.from_now, value: 500)
      totals = ExportActivityToCsv.new(activity: project, report: report).next_four_quarter_forecasts

      expect(totals).to eq ["1000.00", "0.00", "500.00", "0.00"]
    end
  end

  describe "#headers" do
    it "uses the current report financial quarter to generate the actuals total column" do
      travel_to(Date.parse("1 April 2020")) do
        report = Report.new

        headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

        expect(headers).to include "Q1 2020-2021 actuals"
      end
    end

    it "uses the current report financial quarter to generate the forecast total column" do
      travel_to(Date.parse("1 April 2020")) do
        report = Report.new

        headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

        expect(headers).to include "Q1 2020-2021 forecast"
      end
    end

    it "includes the next four financial quarters as headers" do
      travel_to(Date.parse("1 April 2020")) do
        report = Report.new

        headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

        expect(headers).to include ["Q2 2020", "Q3 2020", "Q4 2020", "Q1 2021"].to_csv
      end
    end

    it "returns the headers in the right order" do
      travel_to("2020-09-01") do
        report = Report.new
        headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers
        expect(headers).to include "Funding organisation name",
          "Transparency identifier",
          "Delivery partner identifier",
          "RODA identifier",
          "BEIS identifier",
          "Level",
          "Title",
          "Description",
          "Aims/Objectives",
          "Recipient region",
          "Recipient country",
          "Intended beneficiaries",
          "Programme status",
          "Planned start date",
          "Actual start date",
          "Planned end date",
          "Actual end date",
          "Call open date",
          "Call close date",
          "Total applications",
          "Total awards",
          "Sector",
          "Aid type",
          "Tied status",
          "Finance type",
          "Flow",
          "GDI",
          "Collaboration type",
          "Covid-19 related research",
          "Gender",
          "Climate change - Adaptation",
          "Climate change - Mitigation",
          "Biodiversity",
          "Desertification",
          "Disability",
          "Disaster Risk Reduction",
          "Nutrition policy",
          "ODA eligibility",
          "ODA eligibility lead",
          "Q2 2020-2021 forecast",
          "Q2 2020-2021 actuals",
          "Variance",
          "Comment",
          "Link to activity in RODA"
      end
    end
  end
end
