require "rails_helper"
require "csv"

RSpec.describe ActivitySpendingBreakdown do
  let(:project) { travel_to_quarter(3, 2020) { create(:project_activity, :with_report) } }
  let(:report) { Report.for_activity(project).in_historical_order.first }
  let(:breakdown) { ActivitySpendingBreakdown.new(activity: project, report: report) }

  def create_transaction(financial_year, financial_quarter, value)
    create(:transaction, report: report, parent_activity: project, financial_year: financial_year, financial_quarter: financial_quarter, value: value)
  end

  it "generates columns in the given order" do
    expect(breakdown.headers).to eq([
      "RODA identifier",
      "BEIS identifier",
      "Delivery partner identifier",
      "Title",
      "Description",
      "Programme status",
      "ODA eligibility",

      "FQ1 2019-2020 actual spend", "FQ1 2019-2020 actual refund", "FQ1 2019-2020 actual net",
      "FQ2 2019-2020 actual spend", "FQ2 2019-2020 actual refund", "FQ2 2019-2020 actual net",
      "FQ3 2019-2020 actual spend", "FQ3 2019-2020 actual refund", "FQ3 2019-2020 actual net",
      "FQ4 2019-2020 actual spend", "FQ4 2019-2020 actual refund", "FQ4 2019-2020 actual net",
      "FQ1 2020-2021 actual spend", "FQ1 2020-2021 actual refund", "FQ1 2020-2021 actual net",
      "FQ2 2020-2021 actual spend", "FQ2 2020-2021 actual refund", "FQ2 2020-2021 actual net",
      "FQ3 2020-2021 actual spend", "FQ3 2020-2021 actual refund", "FQ3 2020-2021 actual net",
    ])
  end

  it "exports some metadata relating to the activity" do
    presenter = ActivityPresenter.new(project)

    expect(breakdown.combined_hash).to include(
      "RODA identifier" => project.roda_identifier,
      "BEIS identifier" => project.beis_id,
      "Delivery partner identifier" => project.delivery_partner_identifier,
      "Title" => project.title,
      "Description" => project.description,
      "Programme status" => presenter.programme_status,
      "ODA eligibility" => presenter.oda_eligibility
    )
  end

  describe "detailed spending columns" do
    context "with a positive transaction" do
      before do
        create_transaction(2020, 3, 50)
      end

      it "includes the transaction as a spend and net value" do
        expect(breakdown.combined_hash).to include(
          "FQ3 2020-2021 actual spend" => "50.00",
          "FQ3 2020-2021 actual refund" => "0.00",
          "FQ3 2020-2021 actual net" => "50.00"
        )
      end

      it "includes a zero value for quarters with no transactions" do
        expect(breakdown.combined_hash).to include(
          "FQ2 2020-2021 actual spend" => "0.00",
          "FQ2 2020-2021 actual refund" => "0.00",
          "FQ2 2020-2021 actual net" => "0.00"
        )
      end
    end

    context "with multiple positive transactions" do
      before do
        create_transaction(2020, 2, 80)
        create_transaction(2020, 2, 160)

        create_transaction(2020, 3, 10)
        create_transaction(2020, 3, 20)
        create_transaction(2020, 3, 40)
      end

      it "includes the sum of the transaction values by quarter" do
        expect(breakdown.combined_hash).to include(
          "FQ2 2020-2021 actual spend" => "240.00",
          "FQ2 2020-2021 actual refund" => "0.00",
          "FQ2 2020-2021 actual net" => "240.00",

          "FQ3 2020-2021 actual spend" => "70.00",
          "FQ3 2020-2021 actual refund" => "0.00",
          "FQ3 2020-2021 actual net" => "70.00",
        )
      end
    end

    context "with positive and negative transactions" do
      before do
        create_transaction(2020, 3, 10)
        create_transaction(2020, 3, -20)
        create_transaction(2020, 3, 40)
      end

      it "includes the sum of the transaction spend, refund, and net" do
        expect(breakdown.combined_hash).to include(
          "FQ3 2020-2021 actual spend" => "50.00",
          "FQ3 2020-2021 actual refund" => "20.00",
          "FQ3 2020-2021 actual net" => "30.00",
        )
      end
    end

    context "with net negative transactions" do
      before do
        create_transaction(2020, 3, 10)
        create_transaction(2020, 3, 20)
        create_transaction(2020, 3, -40)
      end

      it "includes the sum of the transaction spend, refund, and net" do
        expect(breakdown.combined_hash).to include(
          "FQ3 2020-2021 actual spend" => "30.00",
          "FQ3 2020-2021 actual refund" => "40.00",
          "FQ3 2020-2021 actual net" => "-10.00",
        )
      end
    end
  end
end
