RSpec.describe Export::AllActivityTotals do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @activity = create(:project_activity)

    @q1_report = create(:report, financial_quarter: 1, financial_year: 2020)
    @q2_report = create(:report, financial_quarter: 2, financial_year: 2020)
    @q3_report = create(:report, financial_quarter: 3, financial_year: 2020)
    @q4_report = create(:report, financial_quarter: 4, financial_year: 2020)

    create_fixtures(
      <<~TABLE
        |transaction|report|financial_period|value|
        | Actual    |q1    | q1             |  100|
        | Adj. Act. |q2    | q1             |  200|
        | Adj. Act. |q2    | q1             | -100|
        | Refund    |q2    | q1             | -200|
        | Adj. Ref. |q2    | q1             |   50|
        | Adj. Ref. |q2    | q1             | -200|
        | Actual    |q3    | q3             |  125|
        | Adj. Act. |q4    | q3             |  200|
        | Adj. Act. |q4    | q3             | -100|
        | Refund    |q4    | q3             | -200|
        | Adj. Ref. |q4    | q3             |  100|
        | Adj. Ref. |q4    | q3             | -200|
        | Actual    |q4    | q4             |  175|
        | Adj. Act. |q4    | q1             |  500|
        | Adj. Ref. |q4    | q1             |  400|
      TABLE
    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "when no report is passed in" do
    subject { described_class.new(activity: @activity, report: nil) }

    it "returns all totals for Q1 including those added in a later report" do
      all_q1_totals = {
        [@activity.id, 1, 2020, "Actual", nil] => BigDecimal(100),
        [@activity.id, 1, 2020, "Adjustment", "Actual"] => BigDecimal(200 - 100 + 500),
        [@activity.id, 1, 2020, "Adjustment", "Refund"] => BigDecimal(50 - 200 + 400),
        [@activity.id, 1, 2020, "Refund", nil] => BigDecimal(-200),
      }

      expect(subject.call).to include all_q1_totals
    end

    it "returns all totals for Q3 including those added in a later report" do
      all_q3_totals = {
        [@activity.id, 3, 2020, "Actual", nil] => BigDecimal(125),
        [@activity.id, 3, 2020, "Adjustment", "Actual"] => BigDecimal(200 + -100),
        [@activity.id, 3, 2020, "Adjustment", "Refund"] => BigDecimal(100 + -200),
        [@activity.id, 3, 2020, "Refund", nil] => BigDecimal(-200),
      }

      expect(subject.call).to include all_q3_totals
    end
  end

  context "when the Q3 report is passed in" do
    subject { described_class.new(activity: @activity, report: @q3_report) }

    it "returns the totals up to and including Q3" do
      all_totals_at_q3 = {
        [@activity.id, 1, 2020, "Actual", nil] => BigDecimal(100),
        [@activity.id, 1, 2020, "Adjustment", "Actual"] => BigDecimal(200 + -100),
        [@activity.id, 1, 2020, "Adjustment", "Refund"] => BigDecimal(50 + -200),
        [@activity.id, 1, 2020, "Refund", nil] => BigDecimal(-200),
        [@activity.id, 3, 2020, "Actual", nil] => BigDecimal(125),
      }
      expect(subject.call).to eq all_totals_at_q3
    end

    it "does not include any actual spend or refunds after Q3" do
      later_totals = {
        [@activity.id, 4, 2020, "Actual", nil] => anything,
        [@activity.id, 4, 2020, "Adjustment", "Actual"] => anything,
        [@activity.id, 4, 2020, "Adjustment", "Refund"] => anything,
        [@activity.id, 4, 2020, "Refund", nil] => anything,
      }
      expect(subject.call).not_to include later_totals
    end

    it "does not include adjustments added after the Q3 report" do
      expect(subject.call).not_to include [@activity.id, 1, 2020, "Adjustment", "Refund"] => BigDecimal(400)
      expect(subject.call).not_to include [@activity.id, 1, 2020, "Adjustment", "Actual"] => BigDecimal(500)
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
