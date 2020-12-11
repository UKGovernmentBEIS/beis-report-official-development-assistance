require "rails_helper"
require "csv"

RSpec.describe ExportActivityToCsv do
  let(:project) { create(:project_activity, :with_report) }
  let(:report) { Report.for_activity(project).first }
  let!(:comment) { create(:comment, report: report, activity: project) }

  describe "#call" do
    it "creates a CSV line which contains all columns in order, followed by forecasts for the next twelve financial quarters" do
      travel_to(Date.parse("1 April 2020")) do
        export_service = ExportActivityToCsv.new(activity: project, report: report)

        allow(export_service).to receive(:columns).and_return(
          "Header A" => -> { "Value A" },
          "Header B" => -> { "Value B" },
          "Header C" => -> { "Value C" },
        )

        result = export_service.call

        expect(result).to eql("Value A,Value B,Value C,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00\n")
      end
    end

    it "includes the BEIS id if there is one" do
      project.update(beis_id: "GCRF_AHRC_NS_AH1001")
      activity_presenter = ActivityCsvPresenter.new(project)
      export_service = ExportActivityToCsv.new(activity: project, report: report)
      result = export_service.call

      expect(result).to include activity_presenter.beis_id
    end
  end

  describe "#next_twelve_quarter_forecasts" do
    it "gets the forecasted total for the next twelve quarters" do
      quarters = report.next_twelve_financial_quarters
      q1_forecast = PlannedDisbursementHistory.new(project, *quarters[0])
      q3_forecast = PlannedDisbursementHistory.new(project, *quarters[2])
      q11_forecast = PlannedDisbursementHistory.new(project, *quarters[10])

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

  describe "#headers" do
    it "generates a CSV header row for all columns in order, followed by the next twelve financial quarters" do
      travel_to(Date.parse("1 April 2020")) do
        export_service = ExportActivityToCsv.new(activity: project, report: report)

        allow(export_service).to receive(:columns).and_return(
          "Header A" => -> { "Value A" },
          "Header B" => -> { "Value B" },
          "Header C" => -> { "Value C" },
        )

        headers = export_service.headers

        expect(headers).to eql("Header A,Header B,Header C,Q2 2020,Q3 2020,Q4 2020,Q1 2021,Q2 2021,Q3 2021,Q4 2021,Q1 2022,Q2 2022,Q3 2022,Q4 2022,Q1 2023\n")
      end
    end

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

    it "includes the next twelve financial quarters as headers" do
      travel_to(Date.parse("1 April 2020")) do
        report = Report.new

        headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

        expect(headers).to include [
          "Q2 2020", "Q3 2020", "Q4 2020", "Q1 2021",
          "Q2 2021", "Q3 2021", "Q4 2021", "Q1 2022",
          "Q2 2022", "Q3 2022", "Q4 2022", "Q1 2023",
        ].to_csv
      end
    end
  end
end
