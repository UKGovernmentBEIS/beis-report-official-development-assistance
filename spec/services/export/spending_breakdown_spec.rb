RSpec.describe Export::SpendingBreakdown do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @organisation = create(:partner_organisation, beis_organisation_reference: "BC")
    @activity = create(:project_activity, organisation: @organisation)
    @source_fund = Fund.new(1)

    q1_2019_report = create(
      :report,
      :approved,
      organisation: @activity.organisation,
      fund: @activity.associated_fund,
      financial_quarter: 1,
      financial_year: 2019
    )
    forecasts_for_report_from_table(q1_2019_report,
      <<~TABLE
        |financial_quarter|financial_year|value|
        |1                |2020          |10000|
        |4                |2020          |  500|
        |1                |2021          |10000|
        |4                |2021          |20000|
      TABLE
    )

    q4_2019_report = create(
      :report,
      :approved,
      organisation: @activity.organisation,
      fund: @activity.associated_fund,
      financial_quarter: 4,
      financial_year: 2019
    )
    forecasts_for_report_from_table(q4_2019_report,
      <<~TABLE
        |financial_quarter|financial_year|value|
        |1                |2020          | 5000|
        |4                |2020          | 2500|
        |1                |2021          |20000|
        |4                |2021          |10000|
      TABLE
    )

    @q1_report = create(:report, financial_quarter: 1, financial_year: 2020)
    @q2_report = create(:report, financial_quarter: 2, financial_year: 2020)

    actuals_from_table(
      <<~TABLE
        |transaction|report|financial_period|value|
        | Actual    |q1    | q1             |  100|
        | Adj. Act. |q2    | q1             |  200|
        | Refund    |q1    | q1             | -200|
        | Adj. Ref. |q2    | q1             |   50|
      TABLE
    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject { described_class.new(organisation: @organisation, source_fund: @source_fund) }

  def value_for_header(header_name)
    subject.rows.first[subject.headers.index(header_name)]
  end

  describe "#filename" do
    context "when an organisation IS used in construction" do
      it "includes the organisation reference" do
        newton_fund = Fund.new(1)
        breakdown = described_class.new(
          source_fund: newton_fund,
          organisation: @organisation
        )
        expect(breakdown.filename).to eq("NF_BC_spending_breakdown.csv")
      end
    end

    context "when NO organisation is used in construction" do
      it "leaves out the organisation reference" do
        newton_fund = Fund.new(1)
        breakdown = described_class.new(source_fund: newton_fund)

        expect(breakdown.filename).to eq("NF_spending_breakdown.csv")
      end
    end
  end

  describe "#headers" do
    it "includes the five headings that describe the activity" do
      expect(subject.headers).to include(
        "RODA identifier",
        "Partner organisation identifier",
        "Activity title",
        "Activity level",
        "Activity status"
      )
    end

    it "includes the partner organisation" do
      expect(subject.headers).to include("Partner organisation")
    end

    it "includes the three headings that describe the finances for FQ1 2020-2021" do
      expect(subject.headers).to include(
        "Actual spend FQ1 2020-2021",
        "Refund FQ1 2020-2021",
        "Actual net FQ1 2020-2021"
      )
    end

    it "does NOT contain forecasts for financial quarters where there is actual spend or refund values" do
      expect(subject.headers).not_to include "Forecast FQ1 2020-2021"
    end

    it "includes the correct headers at the boundry between actual spend and refunds and forecasts" do
      expect(subject.headers).not_to include "Forecast FQ1 2020-2021"
      expect(subject.headers).not_to include "Actual spend FQ2 2020-2021"
    end

    it "includes the heading that describe the forecast for FQ1 2021-2022" do
      expect(subject.headers).to include(
        "Forecast FQ1 2021-2022"
      )
    end

    it "includes the heading that describe the forecast for FQ4 2021-2022" do
      expect(subject.headers).to include(
        "Forecast FQ4 2021-2022"
      )
    end

    it "includes the headings that describe the finances for the future financial quarters inbetween" do
      expect(subject.headers).to include(
        "Forecast FQ2 2021-2022",
        "Forecast FQ3 2021-2022"
      )
    end
  end

  describe "#rows" do
    it "contains the appropriate activity values" do
      aggregate_failures do
        expect(value_for_header("RODA identifier")).to eql(@activity.roda_identifier)
        expect(value_for_header("Partner organisation identifier")).to eql(@activity.delivery_partner_identifier)
        expect(value_for_header("Activity title")).to eql(@activity.title)
        expect(value_for_header("Activity level")).to eql("Project (level C)")
        expect(value_for_header("Activity status")).to eql("Spend in progress")
      end
    end

    it "contains the appropriate partner organisation name" do
      expect(value_for_header("Partner organisation")).to eq @activity.organisation.name
    end

    it "contains the financial data for financial quarter 1 2020-2021" do
      aggregate_failures do
        expect(value_for_header("Actual spend FQ1 2020-2021")).to eq BigDecimal(100 + 200)
        expect(value_for_header("Refund FQ1 2020-2021")).to eq BigDecimal(-200 + 50)
        expect(value_for_header("Actual net FQ1 2020-2021")).to eq BigDecimal(100 + 200 + -200 + 50)
      end
    end

    it "contains the latest version of the forecast for FQ1 2021-2022" do
      expect(value_for_header("Forecast FQ1 2021-2022")).to eq BigDecimal("20_000")
    end

    it "contains the latest versions of the forecast for 2021-2022" do
      expect(value_for_header("Forecast FQ4 2021-2022")).to eq BigDecimal("10_000")
    end

    it "contains a zero for the financial quarters inbetween in which there are no forecasts" do
      expect(value_for_header("Forecast FQ2 2021-2022")).to eq 0
      expect(value_for_header("Forecast FQ3 2021-2022")).to eq 0
    end

    it "attibute rows are only create once" do
      rows_data_double = double(Hash, fetch: [], empty?: false)

      attribute_double = double(rows: rows_data_double)
      allow(Export::ActivityAttributesColumns).to receive(:new).and_return(attribute_double)

      partner_organisation_double = double(rows: rows_data_double)
      allow(Export::ActivityPartnerOrganisationColumn).to receive(:new).and_return(partner_organisation_double)

      actuals_double = double(rows: rows_data_double, last_financial_quarter: FinancialQuarter.new(2, 2021))
      allow(Export::ActivityActualsColumns).to receive(:new).and_return(actuals_double)

      forecasts_double = double(rows: rows_data_double)
      allow(Export::ActivityForecastColumns).to receive(:new).and_return(forecasts_double)

      subject.rows

      expect(attribute_double)
        .to have_received(:rows)
        .once

      expect(partner_organisation_double)
        .to have_received(:rows)
        .once

      expect(actuals_double)
        .to have_received(:rows)
        .once

      expect(forecasts_double)
        .to have_received(:rows)
        .once
    end

    context "where there are additional activities" do
      before do
        create_list(:project_activity, 4, organisation: @organisation)
      end

      it "includes a row for each" do
        expect(subject.rows.count).to eq(5)
      end
    end

    context "when there are no activities" do
      let(:fund) { create(:fund_activity) }
      let(:organisation) { create(:partner_organisation) }
      subject { described_class.new(source_fund: fund, organisation: organisation) }

      it "returns the activity attribute headers only" do
        activity_attribute_headers = [
          "RODA identifier",
          "Partner organisation identifier",
          "Activity title",
          "Activity level",
          "Activity status"
        ]
        expect(subject.headers).to match_array(activity_attribute_headers)
        expect(subject.rows).to eq []
      end
    end

    context "when there are actvities but NONE have actual spend, refunds and forecasts" do
      before do
        @organisation = create(:partner_organisation)
        @activities = create_list(:project_activity, 3, organisation: @organisation)

        subject {
          described_class.new(
            source_fund: @activities.first.source_fund_code,
            organisation: @organisation
          )
        }
      end

      it "returns the activity attribute headers only" do
        activity_attribute_headers = [
          "RODA identifier",
          "Partner organisation identifier",
          "Activity title",
          "Activity level",
          "Activity status",
          "Partner organisation"
        ]
        expect(subject.headers).to match_array(activity_attribute_headers)
        expect(subject.rows.count).to eq 3
      end
    end
  end
end
