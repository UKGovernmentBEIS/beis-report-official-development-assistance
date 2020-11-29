require "rails_helper"

RSpec.describe ImportPlannedDisbursements do
  let(:project) { create(:project_activity) }
  let(:reporting_cycle) { ReportingCycle.new(project, 1, 2020) }
  let(:selected_report) { Report.in_historical_order.first }

  let :importer do
    ImportPlannedDisbursements.new(report: selected_report)
  end

  before do
    2.times { reporting_cycle.tick }
    Report.in_historical_order.first.update!(state: :in_review)
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

  context "when the selected report is not the latest one" do
    let(:latest_report) { Report.in_historical_order.first }
    let(:selected_report) { Report.in_historical_order.to_a.last }

    let(:organisation) { project.organisation.name }
    let(:fund) { project.associated_fund.roda_identifier }

    before do
      importer.import([
        {
          "RODA identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        "The report #{selected_report.id} (#{organisation}, Q1 2020 for #{fund}, approved)\
 is not the latest for that organisation and fund. The latest is #{latest_report.id},\
 for Q2 2020 (in_review).",
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
          "RODA identifier" => "not-really-an-id",
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        "The RODA identifier 'not-really-an-id' was not recognised.",
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
        "The forecast for FC 2020/21 FY Q3 (Oct, Nov, Dec) for activity #{project.roda_identifier} is not a number.",
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
          "RODA identifier" => project.roda_identifier,
          "FC 2020/21 FY Q3 (Oct, Nov, Dec)" => "200436",
        },
        {
          "RODA identifier" => unrelated_project.roda_identifier,
          "FC 2020/21 FY Q4 (Jan, Feb, Mar)" => "310793",
        },
      ])
    end

    it "reports an error" do
      expect(importer.errors).to eq([
        "The activity #{unrelated_project.roda_identifier} is not related to the report, which belongs to #{fund} and #{organisation}.",
      ])
    end

    it "does not import any forecasts" do
      expect(forecast_values).to eq([])
    end
  end
end
