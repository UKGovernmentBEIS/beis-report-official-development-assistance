require "rails_helper"

RSpec.describe ImportPlannedDisbursements do
  let(:project) { create(:project_activity) }
  let(:reporting_cycle) { ReportingCycle.new(project, 1, 2020) }

  let :importer do
    ImportPlannedDisbursements.new
  end

  before do
    reporting_cycle.tick
  end

  def forecast_values
    overview = PlannedDisbursementOverview.new(project)

    overview.latest_values.map do |planned_disbursement|
      [
        planned_disbursement.financial_quarter,
        planned_disbursement.financial_year,
        planned_disbursement.value,
      ]
    end
  end

  describe "importing a row of forecasts" do
    let :forecast_row do
      {
        "RODA identifier" => project.roda_identifier,
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

  context "when the data includes an unknown RODA identifier" do
    before do
      importer.import([
        {
          "RODA identifier" => "not-really-an-id",
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        ImportPlannedDisbursements::Error.new(0, "RODA identifier", "not-really-an-id", t("importer.errors.planned_disbursement.unknown_identifier")),
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
          "RODA identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "not a number",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        ImportPlannedDisbursements::Error.new(0, "FC 2020/21 FY Q3 (Oct, Nov, Dec)", "not a number", t("importer.errors.planned_disbursement.non_numeric_value")),
      ])
    end

    it "does not import any forecasts" do
      expect(forecast_values).to eq([])
    end
  end
end
