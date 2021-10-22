RSpec.describe Export::SpendingBreakdown do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @organisation = create(:delivery_partner_organisation, beis_organisation_reference: "BC")
    @activity = create(:project_activity, organisation: @organisation)
    @source_fund = Fund.new(1)

    q1_2019_report = create(
      :report,
      :approved,
      organisation: @organisation,
      fund: @activity.associated_fund,
      financial_quarter: 1,
      financial_year: 2019
    )

    ForecastHistory
      .new(@activity, report: q1_2019_report, financial_quarter: 1, financial_year: 2020)
      .set_value(10_000)
    ForecastHistory
      .new(@activity, report: q1_2019_report, financial_quarter: 4, financial_year: 2020)
      .set_value(5_00)
    ForecastHistory
      .new(@activity, report: q1_2019_report, financial_quarter: 1, financial_year: 2021)
      .set_value(10_000)
    ForecastHistory
      .new(@activity, report: q1_2019_report, financial_quarter: 4, financial_year: 2021)
      .set_value(20_000)

    q4_2019_report = create(
      :report,
      :approved,
      organisation: @organisation,
      fund: @activity.associated_fund,
      financial_quarter: 4,
      financial_year: 2019
    )

    ForecastHistory
      .new(@activity, report: q4_2019_report, financial_quarter: 1, financial_year: 2020)
      .set_value(5_000)
    ForecastHistory
      .new(@activity, report: q4_2019_report, financial_quarter: 4, financial_year: 2020)
      .set_value(2_500)
    ForecastHistory
      .new(@activity, report: q4_2019_report, financial_quarter: 1, financial_year: 2021)
      .set_value(20_000)
    ForecastHistory
      .new(@activity, report: q4_2019_report, financial_quarter: 4, financial_year: 2021)
      .set_value(10_000)

    @q1_report = create(:report, financial_quarter: 1, financial_year: 2020)

    create_fixtures(
      <<~TABLE
        |transaction|report|financial_period|value|
        | Actual    |q1    | q1             |  100|
        | Adj. Act. |q1    | q1             |  200|
        | Refund    |q1    | q1             | -200|
        | Adj. Ref. |q1    | q1             |   50|
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
        "Delivery partner identifier",
        "Activity title",
        "Activity level",
        "Activity status",
      )
    end

    it "includes the delivery partner organisation" do
      expect(subject.headers).to include("Delivery partner organisation")
    end

    it "includes the three headings that describe the finances for FQ1 2020-2021" do
      expect(subject.headers).to include(
        "Actual spend FQ1 2020-2021",
        "Refund FQ1 2020-2021",
        "Actual net FQ1 2020-2021",
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
        "Forecast FQ1 2021-2022",
      )
    end

    it "includes the heading that describe the forecast for FQ4 2021-2022" do
      expect(subject.headers).to include(
        "Forecast FQ4 2021-2022",
      )
    end

    it "includes the headings that describe the finances for the future financial quarters inbetween" do
      expect(subject.headers).to include(
        "Forecast FQ2 2021-2022",
        "Forecast FQ3 2021-2022",
      )
    end
  end

  describe "#rows" do
    it "contains the appropriate activity values" do
      aggregate_failures do
        expect(value_for_header("RODA identifier")).to eql(@activity.roda_identifier)
        expect(value_for_header("Delivery partner identifier")).to eql(@activity.delivery_partner_identifier)
        expect(value_for_header("Activity title")).to eql(@activity.title)
        expect(value_for_header("Activity level")).to eql("Project (level C)")
        expect(value_for_header("Activity status")).to eql("Spend in progress")
      end
    end

    it "contains the appropriate delivery partner name" do
      expect(value_for_header("Delivery partner organisation")).to eq @activity.organisation.name
    end

    it "contains the financial data for financial quarter 1 2020-2021" do
      aggregate_failures do
        expect(value_for_header("Actual spend FQ1 2020-2021")).to eq BigDecimal(100 + 200)
        expect(value_for_header("Refund FQ1 2020-2021")).to eq BigDecimal(-200 + 50)
        expect(value_for_header("Actual net FQ1 2020-2021")).to eq BigDecimal(100 + 200 + -200 + 50)
      end
    end

    it "contains the latest version of the forecast for FQ1 2021-2022" do
      expect(value_for_header("Forecast FQ1 2021-2022")).to eq BigDecimal(20_000)
    end

    it "contains the latest versions of the forecast for 2021-2022" do
      expect(value_for_header("Forecast FQ4 2021-2022")).to eq BigDecimal(10_000)
    end

    it "contains a zero for the financial quarters inbetween in which there are no forecasts" do
      expect(value_for_header("Forecast FQ2 2021-2022")).to eq 0
      expect(value_for_header("Forecast FQ3 2021-2022")).to eq 0
    end

    context "where there are additional activities" do
      before do
        create_list(:project_activity, 4, organisation: @organisation)
      end

      it "includes a row for each" do
        expect(subject.rows.count).to eq(5)
      end
    end

    context "when there are no actual spend, refunds and forecasts" do
      let(:activities) { create_list(:project_activity, 5) }
      subject { described_class.new(source_fund: activities.first.associated_fund, organisation: activities.first.organisation) }

      it "returns the activity attribute headers only" do
        activity_attribute_headers = [
          "RODA identifier",
          "Delivery partner identifier",
          "Activity title",
          "Activity level",
          "Activity status",
        ]
        expect(subject.headers).to match_array(activity_attribute_headers)
        expect(subject.rows).to eq []
      end
    end
  end

  def create_fixtures(table)
    CSV.parse(table, col_sep: "|", headers: true).each do |row|
      case row["transaction"].strip
      when "Actual"
        create(:actual, fixture_attrs(row))
      when "Adj. Act."
        create(:adjustment, :actual, fixture_attrs(row))
      when "Adj. Ref."
        create(:adjustment, :refund, fixture_attrs(row))
      when "Refund"
        create(:refund, fixture_attrs(row))
      else
        raise "don't know what to do"
      end
    end
  end

  def fixture_attrs(row)
    {
      parent_activity: @activity,
      value: row["value"].strip,
      financial_quarter: row["financial_period"][/\d/],
      financial_year: 2020,
      report: instance_variable_get("@#{row["report"].strip}_report"),
    }
  end
end
