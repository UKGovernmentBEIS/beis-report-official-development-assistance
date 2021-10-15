RSpec.describe Export::ActivityForecastColumns do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @activity = create(:project_activity)
    @organisation = create(:delivery_partner_organisation, beis_organisation_reference: "BC")
    @source_fund = Fund.new(1)
    other_activities = create_list(:project_activity, 4)

    @activities = [@activity] + other_activities

    create_old_report_and_forecasts
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject { Export::ActivityForecastColumns.new(activities: @activities) }

  let(:attributes) { [:roda_identifier, :delivery_partner_identifier] }

  describe "#headers" do
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
  end

  describe "#rows" do
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

    it "includes a row for each acitvity" do
      expect(subject.rows.count).to eq(5)
    end

    context "when there are no activities" do
      subject { Export::ActivityForecastColumns.new(activities: []) }

      it "returns an empty array" do
        expect(subject.headers).to eql []
        expect(subject.rows).to eql []
      end
    end
  end

  def value_for_header(header_name)
    values = subject.rows.fetch(@activity.id)
    values[subject.headers.index(header_name)]
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
