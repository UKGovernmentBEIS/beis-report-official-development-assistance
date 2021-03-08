require "rails_helper"
require "csv"

RSpec.describe ExportActivityToCsv do
  let(:project) { travel_to_quarter(1, 2020) { create(:project_activity, :with_report) } }
  let(:report) { Report.for_activity(project).first }
  let(:export_service) { ExportActivityToCsv.new(activity: project, report: report) }

  let(:previous_twelve_quarter_actuals_headers) {
    [
      "FQ1 2017-2018 actuals", "FQ2 2017-2018 actuals", "FQ3 2017-2018 actuals", "FQ4 2017-2018 actuals",
      "FQ1 2018-2019 actuals", "FQ2 2018-2019 actuals", "FQ3 2018-2019 actuals", "FQ4 2018-2019 actuals",
      "FQ1 2019-2020 actuals", "FQ2 2019-2020 actuals", "FQ3 2019-2020 actuals", "FQ4 2019-2020 actuals",
    ]
  }
  let(:previous_twelve_quarter_actuals_values) {
    [
      "420.00", "430.00", "440.00", "450.00",
      "460.00", "470.00", "480.00", "490.00",
      "500.00", "510.00", "520.00", "530.00",
    ]
  }

  let(:next_twenty_quarter_forecast_headers) {
    [
      "FQ2 2020-2021 forecast", "FQ3 2020-2021 forecast", "FQ4 2020-2021 forecast", "FQ1 2021-2022 forecast",
      "FQ2 2021-2022 forecast", "FQ3 2021-2022 forecast", "FQ4 2021-2022 forecast", "FQ1 2022-2023 forecast",
      "FQ2 2022-2023 forecast", "FQ3 2022-2023 forecast", "FQ4 2022-2023 forecast", "FQ1 2023-2024 forecast",
      "FQ2 2023-2024 forecast", "FQ3 2023-2024 forecast", "FQ4 2023-2024 forecast", "FQ1 2024-2025 forecast",
      "FQ2 2024-2025 forecast", "FQ3 2024-2025 forecast", "FQ4 2024-2025 forecast", "FQ1 2025-2026 forecast",
    ]
  }
  let(:next_twenty_quarter_forecast_values) {
    [
      "20.00", "30.00", "40.00", "50.00",
      "60.00", "70.00", "80.00", "90.00",
      "100.00", "110.00", "120.00", "130.00",
      "140.00", "150.00", "160.00", "170.00",
      "180.00", "190.00", "200.00", "210.00",
    ]
  }

  before do
    allow(export_service).to receive(:previous_twelve_quarter_actuals).and_return(previous_twelve_quarter_actuals_values)
    allow(export_service).to receive(:next_twenty_quarter_forecasts).and_return(next_twenty_quarter_forecast_values)
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

    it "includes the actuals for the previous twelve quarters" do
      expect(export_service.headers.drop(3).take(12)).to eq(previous_twelve_quarter_actuals_headers)
      expect(export_service.call.drop(3).take(12)).to eq(previous_twelve_quarter_actuals_values)
    end

    it "includes the forecasts for the next twenty quarters" do
      expect(export_service.headers.drop(15).take(20)).to eq(next_twenty_quarter_forecast_headers)
      expect(export_service.call.drop(15).take(20)).to eq(next_twenty_quarter_forecast_values)
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

  describe "#previous_twelve_quarter_actuals" do
    let(:previous_quarter_report) { travel_to_quarter(4, 2019) { create(:report) } }
    let(:previous_year_report) { travel_to_quarter(4, 2018) { create(:report) } }

    it "gets the actual totals for the previous twelve quarters" do
      create(:transaction, parent_activity: project, report: previous_quarter_report, financial_quarter: 4, financial_year: 2019, value: 20)
      create(:transaction, parent_activity: project, report: previous_quarter_report, financial_quarter: 1, financial_year: 2019, value: 40)
      create(:transaction, parent_activity: project, report: previous_year_report, financial_quarter: 3, financial_year: 2017, value: 80)

      totals = ExportActivityToCsv.new(activity: project, report: report).previous_twelve_quarter_actuals

      expect(totals).to eq [
        "0.00", "0.00", "80.00", "0.00",
        "0.00", "0.00", "0.00", "0.00",
        "40.00", "0.00", "0.00", "20.00",
      ]
    end
  end

  describe "#next_twenty_quarter_forecasts" do
    it "gets the forecasted total for the next twenty quarters" do
      quarters = report.own_financial_quarter.following(20)
      q1_forecast = PlannedDisbursementHistory.new(project, **quarters[0])
      q3_forecast = PlannedDisbursementHistory.new(project, **quarters[2])
      q11_forecast = PlannedDisbursementHistory.new(project, **quarters[18])

      q1_forecast.set_value(1000)
      q3_forecast.set_value(500)
      q11_forecast.set_value(300)

      totals = ExportActivityToCsv.new(activity: project, report: report).next_twenty_quarter_forecasts

      expect(totals).to eq [
        "1000.00", "0.00", "500.00", "0.00",
        "0.00", "0.00", "0.00", "0.00",
        "0.00", "0.00", "0.00", "0.00",
        "0.00", "0.00", "0.00", "0.00",
        "0.00", "0.00", "300.00", "0.00",
      ]
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
