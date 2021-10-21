RSpec.describe Export::SpendingBreakdown do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @organisation = create(:delivery_partner_organisation, beis_organisation_reference: "BC")
    @activity = create(:project_activity, organisation: @organisation)
    @source_fund = Fund.new(1)

    create_q1_2020_actual_and_adjustments
    create_q4_2020_actual_and_adjustments

    create_q1_2020_refund_and_adjustments
    create_q4_2020_refund_and_adjustments

    create_old_report_and_forecasts
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
        "Delivery partner organisation",
        "Title",
        "Level",
        "Activity status",
      )
    end

    it "includes the three headings that describe the finances for financial quarter 1 2020-2021" do
      expect(subject.headers).to include(
        "Actual spend FQ1 2020-2021",
        "Refund FQ1 2020-2021",
        "Actual net FQ1 2020-2021",
      )
    end

    it "includes the three headings that describe the finances for financial quarter 4 2020-2021" do
      expect(subject.headers).to include(
        "Actual spend FQ4 2020-2021",
        "Refund FQ4 2020-2021",
        "Actual net FQ4 2020-2021",
      )
    end

    it "includes the three headings that describe the finances for financial quarters inbetween" do
      expect(subject.headers).to include(
        "Actual spend FQ2 2020-2021",
        "Refund FQ2 2020-2021",
        "Actual net FQ2 2020-2021",
      )
      expect(subject.headers).to include(
        "Actual spend FQ3 2020-2021",
        "Refund FQ3 2020-2021",
        "Actual net FQ3 2020-2021",
      )
    end

    it "does NOT contain forecasts for financial quarters where there is actual spend or refund values" do
      expect(subject.headers).not_to include "Forecast FQ1 2020-2021"
      expect(subject.headers).not_to include "Forecast FQ4 2020-2021"
    end

    it "includes the correct headers at the boundry between actual spend and refunds and forecasts" do
      expect(subject.headers).not_to include "Forecast FQ4 2020-2021"
      expect(subject.headers).not_to include "Actual spend FQ1 2021-2022"
    end

    it "includes the heading that describe the finances for the future financial quarter FQ1 2021-2022" do
      expect(subject.headers).to include(
        "Forecast FQ1 2021-2022",
      )
    end

    it "includes the heading that describe the finances for the future financial quarter FQ4 2021-2022" do
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

    context "when there are no forecasts" do
      before do
        allow(subject).to receive(:forecasts).and_return([])
      end

      it "should not return any forecast headers" do
        expect(subject.headers.any? { |header| header.match(/Forecast/) }).to eq(false)
      end
    end
  end

  describe "#rows" do
    it "contains the appropriate activity values" do
      aggregate_failures do
        expect(value_for_header("RODA identifier")).to eql(@activity.roda_identifier)
        expect(value_for_header("Delivery partner identifier")).to eql(@activity.delivery_partner_identifier)
        expect(value_for_header("Delivery partner organisation")).to eql(@activity.organisation.name)
        expect(value_for_header("Title")).to eql(@activity.title)
        expect(value_for_header("Level")).to eql("Project (level C)")
        expect(value_for_header("Activity status")).to eql("Spend in progress")
      end
    end

    it "contains the financial data for financial quarter 1 2020-2021" do
      aggregate_failures do
        expect(value_for_header("Actual spend FQ1 2020-2021").to_s).to eql("200.0")
        expect(value_for_header("Refund FQ1 2020-2021").to_s).to eql("-350.0")
        expect(value_for_header("Actual net FQ1 2020-2021").to_s).to eql("-150.0")
      end
    end

    it "contains the financial data for financial quarter 4 2020-2021" do
      aggregate_failures do
        expect(value_for_header("Actual spend FQ4 2020-2021").to_s).to eql("200.0")
        expect(value_for_header("Refund FQ4 2020-2021").to_s).to eql("-350.0")
        expect(value_for_header("Actual net FQ4 2020-2021").to_s).to eql("-150.0")
      end
    end

    it "contains zero values for the financial quarters inbetween" do
      aggregate_failures do
        expect(value_for_header("Actual spend FQ2 2020-2021").to_s).to eql("0")
        expect(value_for_header("Refund FQ2 2020-2021").to_s).to eql("0")
        expect(value_for_header("Actual net FQ2 2020-2021").to_s).to eql("0")

        expect(value_for_header("Actual spend FQ3 2020-2021").to_s).to eql("0")
        expect(value_for_header("Refund FQ3 2020-2021").to_s).to eql("0")
        expect(value_for_header("Actual net FQ3 2020-2021").to_s).to eql("0")
      end
    end

    it "contains the financial data for financial quarter 1 2021-2022" do
      expect(value_for_header("Forecast FQ1 2021-2022").to_s).to eql("20000.0")
    end

    it "contains the financial data for financial quarter 4 2021-2022" do
      expect(value_for_header("Forecast FQ4 2021-2022").to_s).to eql("10000.0")
    end

    it "contains a zero for the financial quarters inbetween in which there are no forecasts" do
      expect(value_for_header("Forecast FQ2 2021-2022").to_s).to eql "0"
      expect(value_for_header("Forecast FQ3 2021-2022").to_s).to eql "0"
    end

    context "where there are additional activities" do
      before do
        create_list(:project_activity, 4, organisation: @organisation)
      end

      it "includes a row for each" do
        expect(subject.rows.count).to eq(5)
      end
    end
  end

  def create_q1_2020_actual_and_adjustments
    @actual = create(
      :actual,
      parent_activity: @activity,
      value: 100,
      financial_quarter: 1,
      financial_year: 2020
    )
    create(
      :adjustment,
      :actual,
      parent_activity: @activity,
      value: 200,
      financial_quarter: 1,
      financial_year: 2020
    )
    create(
      :adjustment,
      :actual,
      parent_activity: @activity,
      value: -100,
      financial_quarter: 1,
      financial_year: 2020
    )
  end

  def create_q4_2020_actual_and_adjustments
    create(
      :actual,
      parent_activity: @activity,
      value: 100,
      financial_quarter: 4,
      financial_year: 2020
    )
    create(
      :adjustment,
      :actual,
      parent_activity: @activity,
      value: 200,
      financial_quarter: 4,
      financial_year: 2020
    )
    create(
      :adjustment,
      :actual,
      parent_activity: @activity,
      value: -100,
      financial_quarter: 4,
      financial_year: 2020
    )
  end

  def create_q1_2020_refund_and_adjustments
    @refund = create(
      :refund,
      parent_activity: @activity,
      value: -200,
      financial_quarter: 1,
      financial_year: 2020
    )
    create(
      :adjustment,
      :refund,
      parent_activity: @activity,
      value: 50,
      financial_quarter: 1,
      financial_year: 2020
    )
    create(
      :adjustment,
      :refund,
      parent_activity: @activity,
      value: -200,
      financial_quarter: 1,
      financial_year: 2020
    )
  end

  def create_q4_2020_refund_and_adjustments
    create(
      :refund,
      parent_activity: @activity,
      value: -200,
      financial_quarter: 4,
      financial_year: 2020
    )
    create(
      :adjustment,
      :refund,
      parent_activity: @activity,
      value: 50,
      financial_quarter: 4,
      financial_year: 2020
    )
    create(
      :adjustment,
      :refund,
      parent_activity: @activity,
      value: -200,
      financial_quarter: 4,
      financial_year: 2020
    )
  end

  def create_old_report_and_forecasts
    report = create(
      :report,
      :approved,
      organisation: @organisation,
      fund: @activity.associated_fund,
      financial_quarter: 1,
      financial_year: 2019
    )
    ForecastHistory.new(@activity, report: report, financial_quarter: 1, financial_year: 2020)
      .set_value(5_000)
    ForecastHistory.new(@activity, report: report, financial_quarter: 4, financial_year: 2020)
      .set_value(2_500)
    ForecastHistory.new(@activity, report: report, financial_quarter: 1, financial_year: 2021)
      .set_value(20_000)
    ForecastHistory.new(@activity, report: report, financial_quarter: 4, financial_year: 2021)
      .set_value(10_000)
  end
end
