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

      expect(result).to eql("Value A,Value B,Value C,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00\n")
    end

    it "includes the forecast and actuals for previous quarters, if suitable reports are available" do
      fund = report.fund
      organisation = report.organisation

      travel_to_quarter(4, 2019) { Report.create(fund: fund, organisation: organisation) }
      travel_to_quarter(3, 2019) { Report.create(fund: fund, organisation: organisation) }
      travel_to_quarter(2, 2019) { Report.create(fund: fund, organisation: organisation) }

      export_service = ExportActivityToCsv.new(activity: project, report: report)

      allow(export_service).to receive(:columns).and_return(
        "Header A" => -> { "Value A" },
        "Header B" => -> { "Value B" },
        "Header C" => -> { "Value C" },
      )

      result = export_service.call

      expect(result).to eql("Value A,Value B,Value C,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00,0.00\n")
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
      q1_forecast = PlannedDisbursementHistory.new(project, quarters[0].to_i, quarters[0].financial_year.to_i)
      q3_forecast = PlannedDisbursementHistory.new(project, quarters[2].to_i, quarters[2].financial_year.to_i)
      q11_forecast = PlannedDisbursementHistory.new(project, quarters[10].to_i, quarters[10].financial_year.to_i)

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

  describe "#previous_quarters_actuals" do
    it "returns an empty array when there are no previous reports" do
      activity = create(:project_activity)
      organisation = activity.organisation
      fund = activity.associated_fund

      current_report = Report.new(fund: fund, organisation: organisation, state: :active)
      create(:transaction, report: current_report, parent_activity: activity, value: 10000.00)

      exporter = ExportActivityToCsv.new(activity: activity, report: current_report)

      expect(exporter.previous_quarters_actuals).to eq([])
    end

    it "returns the figures for the previous quarters" do
      activity = create(:project_activity)
      organisation = activity.organisation
      fund = activity.associated_fund

      financial_quarter = FinancialQuarter.new(2019, 2)

      ((financial_quarter - 12)..(financial_quarter - 1)).each_with_index do |quarter, i|
        travel_to_quarter(quarter.to_i, quarter.financial_year.to_i) do
          value = (i + 1).to_f
          report = Report.new(fund: fund, organisation: organisation, state: :active)
          create(:transaction, report: report, parent_activity: activity, value: value)
          report.approved!
        end
      end

      travel_to_quarter(financial_quarter.to_i, financial_quarter.financial_year.to_i) do
        current_report = Report.new(fund: fund, organisation: organisation, state: :active)
        create(:transaction, report: current_report, parent_activity: activity, value: 10000.00)

        exporter = ExportActivityToCsv.new(activity: activity, report: current_report)
        expect(exporter.previous_quarters_actuals).to eq([
          "12.00", "11.00", "10.00", "9.00",
          "8.00", "7.00", "6.00", "5.00",
          "4.00", "3.00", "2.00", "1.00",
        ])
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

      expect(headers).to eql("Header A,Header B,Header C,Q2 2020-2021,Q3 2020-2021,Q4 2020-2021,Q1 2021-2022,Q2 2021-2022,Q3 2021-2022,Q4 2021-2022,Q1 2022-2023,Q2 2022-2023,Q3 2022-2023,Q4 2022-2023,Q1 2023-2024\n")
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

      expect(headers).to include [
        "Q2 2020-2021", "Q3 2020-2021", "Q4 2020-2021", "Q1 2021-2022",
        "Q2 2021-2022", "Q3 2021-2022", "Q4 2021-2022", "Q1 2022-2023",
        "Q2 2022-2023", "Q3 2022-2023", "Q4 2022-2023", "Q1 2023-2024",
      ].to_csv
    end

    it "includes the previous quarter's actuals, if it is available" do
      fund = create(:fund_activity)
      organisation = create(:delivery_partner_organisation)

      travel_to_quarter(4, 2019) { Report.new(fund: fund, organisation: organisation).save! }
      travel_to_quarter(3, 2019) { Report.new(fund: fund, organisation: organisation).save! }
      travel_to_quarter(2, 2019) { Report.new(fund: fund, organisation: organisation).save! }

      report = travel_to_quarter(1, 2020) { Report.new(fund: fund, organisation: organisation) }

      headers = ExportActivityToCsv.new(activity: build(:activity), report: report).headers

      expect(headers).to include("Q4 2019-2020 actuals")
      expect(headers).to include("Q3 2019-2020 actuals")
      expect(headers).to include("Q2 2019-2020 actuals")
    end
  end
end
