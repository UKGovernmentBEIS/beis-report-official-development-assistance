require "rails_helper"
require "csv"

RSpec.describe ExportActivityToCsv do
  let(:project) { travel_to_quarter(1, 2020) { create(:project_activity, :with_report) } }
  let(:report) { Report.for_activity(project).first }
  let(:export_service) { ExportActivityToCsv.new(activity: project, report: report) }

  let(:next_twelve_quarter_forecast_headers) {
    [
      "FQ2 2020-2021 forecast", "FQ3 2020-2021 forecast", "FQ4 2020-2021 forecast", "FQ1 2021-2022 forecast",
      "FQ2 2021-2022 forecast", "FQ3 2021-2022 forecast", "FQ4 2021-2022 forecast", "FQ1 2022-2023 forecast",
      "FQ2 2022-2023 forecast", "FQ3 2022-2023 forecast", "FQ4 2022-2023 forecast", "FQ1 2023-2024 forecast",
    ]
  }
  let(:next_twelve_quarter_forecast_values) {
    [
      "20.00", "30.00", "40.00", "50.00",
      "60.00", "70.00", "80.00", "90.00",
      "100.00", "110.00", "120.00", "130.00",
    ]
  }

  before do
    allow(export_service).to receive(:previous_quarter_actuals).and_return("10.00")
    allow(export_service).to receive(:next_twelve_quarter_forecasts).and_return(next_twelve_quarter_forecast_values)
  end

  describe "with arbitrary columns" do
    before do
      allow(export_service).to receive(:columns).and_return(
        "Header A" => -> { "Value A" },
        "Header B" => -> { "Value B" },
        "Header C" => -> { "Value C" },
      )
    end

    it "returns all the columns in order" do
      expect(export_service.headers.take(3)).to eq ["Header A", "Header B", "Header C"]
      expect(export_service.call.take(3)).to eq ["Value A", "Value B", "Value C"]
    end

    it "includes the forecasts for the next twelve quarters" do
      expect(export_service.headers.drop(3).take(12)).to eq(next_twelve_quarter_forecast_headers)
      expect(export_service.call.drop(3).take(12)).to eq(next_twelve_quarter_forecast_values)
    end

    context "when there is a report for the previous quarter" do
      before do
        fund = report.fund
        organisation = report.organisation
        travel_to_quarter(4, 2019) { Report.create(fund: fund, organisation: organisation) }
      end

      it "includes the actual spend for the previous quarter" do
        expect(export_service.headers.take(4)).to eq ["Header A", "Header B", "Header C", "FQ4 2019-2020 actuals"]
        expect(export_service.call.take(4)).to eq ["Value A", "Value B", "Value C", "10.00"]
      end

      it "includes the forecasts for the next twelve quarters" do
        expect(export_service.headers.drop(4).take(12)).to eq(next_twelve_quarter_forecast_headers)
        expect(export_service.call.drop(4).take(12)).to eq(next_twelve_quarter_forecast_values)
      end
    end
  end

  context "when the project has a BEIS identifier" do
    before do
      project.update!(beis_id: "GCRF_AHRC_NS_AH1001")
    end

    it "includes the BEIS identifier" do
      expect(export_service.call).to include("GCRF_AHRC_NS_AH1001")
    end
  end

  describe "#next_twelve_quarter_forecasts" do
    it "gets the forecasted total for the next twelve quarters" do
      quarters = report.own_financial_quarter.following(12)
      q1_forecast = PlannedDisbursementHistory.new(project, **quarters[0])
      q3_forecast = PlannedDisbursementHistory.new(project, **quarters[2])
      q11_forecast = PlannedDisbursementHistory.new(project, **quarters[10])

      q1_forecast.set_value(1000)
      q3_forecast.set_value(500)
      q11_forecast.set_value(300)

      totals = ExportActivityToCsv.new(activity: project, report: report).next_twelve_quarter_forecasts

      expect(totals).to eq [
        "1000.00", "0.00", "500.00", "0.00",
        "0.00", "0.00", "0.00", "0.00",
        "0.00", "0.00", "300.00", "0.00",
      ]
    end
  end

  describe "#previous_quarter_actuals" do
    it "gets the actuals for the previous quarter" do
      activity = create(:project_activity)
      organisation = activity.organisation
      fund = activity.associated_fund

      travel_to_quarter(1, 2019) do
        previous_report = Report.new(fund: fund, organisation: organisation, state: :active)
        create(:transaction, report: previous_report, parent_activity: activity, value: 666.66)
        previous_report.approved!
      end

      travel_to_quarter(2, 2019) do
        current_report = Report.new(fund: fund, organisation: organisation, state: :active)
        create(:transaction, report: current_report, parent_activity: activity, value: 10000.00)

        exporter = ExportActivityToCsv.new(activity: activity, report: current_report)

        expect(exporter.call).to include "666.66"
      end
    end
  end

  describe "#headers" do
    it "uses the current report financial quarter to generate the actuals total column" do
      report = travel_to(Date.parse("1 April 2020")) { Report.new }

      headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

      expect(headers).to include "FQ1 2020-2021 actuals"
    end

    it "uses the current report financial quarter to generate the forecast total column" do
      report = travel_to_quarter(1, 2020) { Report.new }

      headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

      expect(headers).to include "FQ1 2020-2021 forecast"
    end
  end
end
