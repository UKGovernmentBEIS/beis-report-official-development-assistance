require "rails_helper"
require "csv"

RSpec.describe ExportActivityToCsv do
  let(:project) { create(:project_activity, :with_report) }
  let(:report) { Report.find_by(fund: project.associated_fund, organisation: project.organisation) }

  describe "#call" do
    it "creates a CSV line representation of the Activity" do
      activity_presenter = ActivityPresenter.new(project)
      export_service = ExportActivityToCsv.new(activity: project, report: report)
      result = export_service.call
      next_four_quarter_totals = export_service.next_four_quarter_forecasts

      expect(result).to eq([
        activity_presenter.delivery_partner_identifier,
        activity_presenter.transparency_identifier,
        activity_presenter.sector_with_code,
        activity_presenter.title,
        activity_presenter.description,
        activity_presenter.status,
        activity_presenter.planned_start_date,
        activity_presenter.actual_start_date,
        activity_presenter.planned_end_date,
        activity_presenter.actual_end_date,
        activity_presenter.recipient_region,
        activity_presenter.recipient_country,
        activity_presenter.aid_type_with_code,
        activity_presenter.level,
        activity_presenter.actual_total_for_report_financial_quarter(report: report),
        activity_presenter.forecasted_total_for_report_financial_quarter(report: report),
        activity_presenter.variance_for_report_financial_quarter(report: report),
        activity_presenter.link_to_roda,
      ].concat(next_four_quarter_totals).to_csv)
    end
  end

  describe "#next_four_quarter_forecasts" do
    it "gets the forecasted total for the date ranges of the next four quarters" do
      _disbursement_1 = create(:planned_disbursement, parent_activity: project, period_start_date: 3.months.from_now, value: 1000)
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
  end
end
