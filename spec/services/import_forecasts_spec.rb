require "rails_helper"

RSpec.describe ImportForecasts do
  let(:project) { create(:project_activity) }

  let(:reporting_cycle) { ReportingCycle.new(project, 1, 2020) }
  let(:latest_report) { Report.in_historical_order.first }
  let(:selected_report) { nil }

  let(:reporter_organisation) { project.organisation }
  let(:reporter) { create(:delivery_partner_user, organisation: reporter_organisation) }

  let :importer do
    ImportForecasts.new(uploader: reporter, report: selected_report)
  end

  before do
    2.times { reporting_cycle.tick }
  end

  def forecast_values
    overview = ForecastOverview.new(project)

    overview.latest_values.map do |forecast|
      [
        forecast.financial_quarter,
        forecast.financial_year,
        forecast.value,
      ]
    end
  end

  describe "importing a row of forecasts" do
    let :forecast_row do
      {
        "Activity RODA Identifier" => project.roda_identifier,
        "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
        "FC 2020/21 FY Q4 (Jan, Feb, Mar)" => "310793",
        "FC 2021/22 FY Q1 (Apr, May, Jun)" => "984150",
        "FC 2021/22 FY Q2 (Jul, Aug, Sep)" => "206206",
      }
    end

    before do
      importer.import([forecast_row])
    end

    it "imports the forecasts" do
      expect(forecast_values).to eq([
        [3, 2020, 200_436.0],
        [4, 2020, 310_793.0],
        [1, 2021, 984_150.0],
        [2, 2021, 206_206.0],
      ])
    end
  end

  context "when the reporter is not authorised to report on the Activity" do
    let(:reporter_organisation) { create(:delivery_partner_organisation) }

    before do
      importer.import([
        {
          "Activity RODA Identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "40",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        ImportForecasts::Error.new(0, "Activity RODA Identifier", project.roda_identifier, t("importer.errors.forecast.unauthorised")),
      ])
    end

    it "does not import any forecasts" do
      expect(forecast_values).to eq([])
    end
  end

  context "when the data includes an unknown RODA identifier" do
    before do
      importer.import([
        {
          "Activity RODA Identifier" => "not-really-an-id",
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        ImportForecasts::Error.new(0, "Activity RODA Identifier", "not-really-an-id", t("importer.errors.forecast.unknown_identifier")),
      ])
    end

    it "does not import any forecasts" do
      expect(forecast_values).to eq([])
    end
  end

  context "when the data includes a non-numeric forecast" do
    before do
      importer.import([
        {
          "Activity RODA Identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "not a number",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        ImportForecasts::Error.new(0, "FC 2020/21 FY Q3 (Oct, Nov, Dec)", "not a number", t("importer.errors.forecast.non_numeric_value")),
      ])
    end

    it "does not import any forecasts" do
      expect(forecast_values).to eq([])
    end
  end

  context "when the data includes a forecast in the past" do
    before do
      importer.import([
        {
          "Activity RODA Identifier" => project.roda_identifier,
          "FC 2015/16 FY Q3 (Oct, Nov, Dec)" => "200436",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        ImportForecasts::Error.new(0, "FC 2015/16 FY Q3 (Oct, Nov, Dec)", "FC 2015/16 FY Q3 (Oct, Nov, Dec)", t("importer.errors.forecast.in_the_past")),
      ])
    end

    it "does not import any forecasts" do
      expect(forecast_values).to eq([])
    end
  end

  context "when the data includes empty cells" do
    before do
      importer.import([
        {
          "Activity RODA Identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "",
          "FC 2020/21 FY Q4 (Jan, Feb, Mar)" => "310793",
        },
      ])
    end

    it "reports no errors" do
      expect(importer.errors).to eq([])
    end

    it "imports the forecasts, ignoring blank cells" do
      expect(forecast_values).to eq([
        [4, 2020, 310_793.0],
      ])
    end
  end

  context "when the data includes unrecognised columns" do
    before do
      importer.import([
        {
          "Activity Name" => "",
          "Activity Delivery Partner Identifier" => "",
          "Activity RODA Identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "10",
          "FC 2020/21 FY Q4 (Jan, Feb, Mar)" => "20",
          "Unknown Column" => "",
        },
        {
          "Activity Name" => "",
          "Activity Delivery Partner Identifier" => "",
          "Activity RODA Identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "10",
          "FC 2020/21 FY Q4 (Jan, Feb, Mar)" => "20",
          "Unknown Column" => "",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        ImportForecasts::Error.new(-1, "Unknown Column", "", t("importer.errors.forecast.unrecognised_column")),
      ])
    end

    it "does not import any forecasts" do
      expect(forecast_values).to eq([])
    end
  end

  context "importing into a specific report" do
    let(:selected_report) { latest_report }
    let(:reporter) { nil }

    describe "importing a row of forecasts to an in-review report" do
      before do
        selected_report.update!(state: :in_review)
      end

      let :forecast_row do
        {
          "Activity RODA Identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
          "FC 2020/21 FY Q4 (Jan, Feb, Mar)" => "310793",
          "FC 2021/22 FY Q1 (Apr, May, Jun)" => "984150",
          "FC 2021/22 FY Q2 (Jul, Aug, Sep)" => "206206",
        }
      end

      before do
        importer.import([forecast_row])
      end

      it "imports the forecasts" do
        expect(forecast_values).to eq([
          [3, 2020, 200_436.0],
          [4, 2020, 310_793.0],
          [1, 2021, 984_150.0],
          [2, 2021, 206_206.0],
        ])
      end

      it "reports no errors" do
        expect(importer.errors).to eq([])
      end
    end

    context "when the selected report is not the latest one" do
      let(:selected_report) { Report.in_historical_order.to_a.last }

      let(:organisation) { project.organisation.name }
      let(:fund) { project.associated_fund.roda_identifier }

      before do
        importer.import([
          {
            "Activity RODA Identifier" => project.roda_identifier,
            "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
          },
        ])
      end

      it "reports an error" do
        expect(importer.errors).to eq([
          ImportForecasts::Error.new(
            nil,
            nil,
            nil,
            "The report #{selected_report.id} (#{organisation}, FQ1 2020-2021 for #{fund}, approved)\
 is not the latest for that organisation and fund. The latest is #{latest_report.id},\
 for FQ2 2020-2021 (active).",
          ),
        ])
      end

      it "does not import any forecasts" do
        expect(forecast_values).to eq([])
      end
    end

    context "when the data includes a project unrelated to the report" do
      let(:unrelated_project) { create(:project_activity) }

      let(:organisation) { project.organisation.name }
      let(:fund) { project.associated_fund.roda_identifier }

      before do
        importer.import([
          {
            "Activity RODA Identifier" => project.roda_identifier,
            "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
          },
          {
            "Activity RODA Identifier" => unrelated_project.roda_identifier,
            "FC 2020/21 FY Q4 (Jan, Feb, Mar)" => "310793",
          },
        ])
      end

      it "reports an error" do
        expect(importer.errors).to eq([
          ImportForecasts::Error.new(
            1,
            "Activity RODA Identifier",
            unrelated_project.roda_identifier,
            "The activity is not related to the report, which belongs to #{fund} and #{organisation}.",
          ),
        ])
      end

      it "does not import any forecasts" do
        expect(forecast_values).to eq([])
      end
    end
  end

  describe "setting an uploader and a report" do
    let(:reporter) { create(:delivery_partner_user, organisation: reporter_organisation) }
    let(:selected_report) { latest_report }

    it "is forbidden" do
      expect { importer }.to raise_error(ArgumentError)
    end
  end
end
