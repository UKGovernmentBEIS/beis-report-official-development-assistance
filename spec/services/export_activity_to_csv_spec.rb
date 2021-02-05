require "rails_helper"
require "csv"

RSpec.describe ExportActivityToCsv do
  let(:project) { travel_to_quarter(1, 2020) { create(:project_activity, :with_report) } }
  let(:report) { Report.for_activity(project).first }

  describe "#call" do
    it "creates a CSV line which contains all columns in order, followed by forecasts for the next twelve financial quarters" do
      export_service = ExportActivityToCsv.new(activity: project, report: report)

      allow(export_service).to receive(:columns).and_return(
        "Header A" => -> { "Value A" },
        "Header B" => -> { "Value B" },
        "Header C" => -> { "Value C" },
      )

      result = export_service.call

      expect(result).to eql [
        "Value A", "Value B", "Value C",
        "0.00", "0.00", "0.00", "0.00",
        "0.00", "0.00", "0.00", "0.00",
        "0.00", "0.00", "0.00", "0.00",
      ]
    end

    it "includes the forecast and actuals for the previous quarter, if a suitable report is available" do
      fund = report.fund
      organisation = report.organisation

      travel_to_quarter(4, 2019) { Report.create(fund: fund, organisation: organisation) }

      export_service = ExportActivityToCsv.new(activity: project, report: report)

      allow(export_service).to receive(:columns).and_return(
        "Header A" => -> { "Value A" },
        "Header B" => -> { "Value B" },
        "Header C" => -> { "Value C" },
      )

      result = export_service.call

      expect(result).to eql [
        "Value A", "Value B", "Value C",
        "0.00", "0.00", "0.00", "0.00",
        "0.00", "0.00", "0.00", "0.00",
        "0.00", "0.00", "0.00", "0.00", "0.00",
      ]
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
    it "generates a CSV header row for all columns in order, followed by the next twelve financial quarters" do
      export_service = ExportActivityToCsv.new(activity: project, report: report)

      allow(export_service).to receive(:columns).and_return(
        "Header A" => -> { "Value A" },
        "Header B" => -> { "Value B" },
        "Header C" => -> { "Value C" },
      )

      headers = export_service.headers

      expect(headers).to eql [
        "Header A", "Header B", "Header C",
        "Q2 2020", "Q3 2020", "Q4 2020", "Q1 2021",
        "Q2 2021", "Q3 2021", "Q4 2021", "Q1 2022",
        "Q2 2022", "Q3 2022", "Q4 2022", "Q1 2023",
      ]
    end

    it "uses the current report financial quarter to generate the actuals total column" do
      report = travel_to(Date.parse("1 April 2020")) { Report.new }

      headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

      expect(headers).to include "Q1 2020-2021 actuals"
    end

    it "uses the current report financial quarter to generate the forecast total column" do
      report = travel_to_quarter(1, 2020) { Report.new }

      headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

      expect(headers).to include "Q1 2020-2021 forecast"
    end

    it "includes the next twelve financial quarters as headers" do
      report = travel_to_quarter(1, 2020) { Report.new }

      headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

      expect(headers.to_csv).to include [
        "Q2 2020", "Q3 2020", "Q4 2020", "Q1 2021",
        "Q2 2021", "Q3 2021", "Q4 2021", "Q1 2022",
        "Q2 2022", "Q3 2022", "Q4 2022", "Q1 2023",
      ].to_csv
    end

    it "includes the previous quarter's actuals, if it is available" do
      fund = create(:fund_activity)
      organisation = create(:delivery_partner_organisation)

      _previous_report = travel_to_quarter(4, 2019) { Report.new(fund: fund, organisation: organisation).save! }
      report = travel_to_quarter(1, 2020) { Report.new(fund: fund, organisation: organisation) }

      headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

      expect(headers).to include("Q4 2019-2020 actuals")
    end
  end
end
