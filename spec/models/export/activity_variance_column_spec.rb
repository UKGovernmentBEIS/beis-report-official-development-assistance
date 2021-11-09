RSpec.describe Export::ActivityVarianceColumn do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @activity = create(:project_activity)
    other_activities = create_list(:project_activity, 4)

    @activities = [@activity] + other_activities

    q1_2021_report = create(
      :report,
      :approved,
      organisation: @activity.organisation,
      fund: @activity.associated_fund,
      financial_quarter: 1,
      financial_year: 2021
    )
    forecasts_for_report_from_table(q1_2021_report,
      <<~TABLE
        |financial_quarter|financial_year|value|
        |2                |2021          |20000|
        |3                |2021          |30000|
        |4                |2021          |40000|
      TABLE
    )

    @q2_report = create(:report, financial_quarter: 2, financial_year: 2021)

    actuals_from_table(
      <<~TABLE
        |transaction|report|financial_period|value|
        | Actual    |q2    | q2             |40000|
      TABLE
    )

    @last_net_actual_spend_column =
      Export::ActivityActualsColumns
        .new(activities: @activities)
        .rows_for_last_financial_quarter
    @first_foecast_column =
      Export::ActivityForecastColumns
        .new(activities: @activities)
        .rows_for_first_financial_quarter
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject {
    Export::ActivityVarianceColumn.new(
      activities: @activities,
      net_actual_spend_column_data: @last_net_actual_spend_column,
      forecast_column_data: @first_foecast_column,
      financial_quarter: FinancialQuarter.new(2021, 2)
    )
  }

  describe "#headers" do
    it "returns the header for the last financial quarter of the net actual spend" do
      expect(subject.headers).to eq ["Variance FQ2 2021-2022"]
    end
  end

  describe "#rows" do
    it "returns the variance" do
      variance_for_activity = subject.rows.fetch(@activity.id)
      expect(variance_for_activity).to eq BigDecimal(20000 - 40000)
    end
  end

  private

  def actuals_from_table(table)
    CSV.parse(table, col_sep: "|", headers: true).each do |row|
      case row["transaction"].strip
      when "Actual"
        create(:actual, fixture_attrs(row))
      when "Refund"
        create(:refund, fixture_attrs(row))
      else
        raise "don't know what to do"
      end
    end
  end

  def forecasts_for_report_from_table(report, table)
    CSV.parse(table, col_sep: "|", headers: true).each do |row|
      ForecastHistory.new(
        @activity,
        report: report,
        financial_quarter: row["financial_quarter"].to_i,
        financial_year: row["financial_year"].to_i,
      ).set_value(row["value"].to_i)
    end
  end

  def fixture_attrs(row)
    {
      parent_activity: @activity,
      value: row["value"].strip,
      financial_quarter: row["financial_period"][/\d/],
      financial_year: 2021,
      report: instance_variable_get("@#{row["report"].strip}_report"),
    }
  end
end
