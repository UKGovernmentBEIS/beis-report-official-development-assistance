RSpec.describe Export::ActivityActualsColumns do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @activity = create(:project_activity)
    other_activities = create_list(:project_activity, 4)

    @activities = [@activity] + other_activities

    @q1_report = create(:report, financial_quarter: 1, financial_year: 2020)
    @q4_report = create(:report, financial_quarter: 4, financial_year: 2020)

    create_fixtures(
      <<~TABLE
        |transaction|report|financial_period|value|
        | Actual    |q1    | q1             |  100|
        | Adj. Act. |q1    | q1             |  200|
        | Adj. Act. |q1    | q1             | -100|
        | Refund    |q1    | q1             | -200|
        | Adj. Ref. |q1    | q1             |   50|
        | Adj. Ref. |q1    | q1             | -200|
        | Actual    |q4    | q4             |  100|
        | Adj. Act. |q4    | q4             |  200|
        | Adj. Act. |q4    | q4             | -100|
        | Refund    |q4    | q4             | -200|
        | Adj. Ref. |q4    | q4             |  100|
        | Adj. Ref. |q4    | q4             | -200|
      TABLE
    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject { described_class.new(activities: @activities, include_breakdown: breakdown) }

  context "when a breakdown is not requested" do
    let(:breakdown) { false }

    describe "#headers" do
      it "returns an array of the column headers for financial quarters in which there is actual spend" do
        headers = [
          "Actual net FQ1 2020-2021",
          "Actual net FQ2 2020-2021",
          "Actual net FQ3 2020-2021",
          "Actual net FQ4 2020-2021",
        ]

        expect(subject.headers).to match_array(headers)
      end
    end

    describe "#rows" do
      it "contains the financial data for financial quarter 1 2020-2021" do
        expect(value_for_header("Actual net FQ1 2020-2021").to_s).to eql("-150.0")
      end

      it "contains the financial data for financial quarter 4 2020-2021" do
        expect(value_for_header("Actual net FQ4 2020-2021").to_s).to eql("-100.0")
      end

      it "contains zero values for the financial quarters inbetween" do
        expect(value_for_header("Actual net FQ2 2020-2021").to_s).to eql("0")
        expect(value_for_header("Actual net FQ3 2020-2021").to_s).to eql("0")
      end

      it "includes a row for each acitvity" do
        expect(subject.rows.count).to eq(5)
      end

      context "when there are no activities" do
        subject { described_class.new(activities: [], include_breakdown: breakdown) }

        it "returns an empty array" do
          expect(subject.headers).to eql []
          expect(subject.rows).to eql []
        end
      end
    end
  end

  context "when a breakdown is requested" do
    let(:breakdown) { true }

    describe "#headers" do
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
    end

    describe "#rows" do
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
          expect(value_for_header("Refund FQ4 2020-2021").to_s).to eql("-300.0")
          expect(value_for_header("Actual net FQ4 2020-2021").to_s).to eql("-100.0")
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

      it "includes a row for each acitvity" do
        expect(subject.rows.count).to eq(5)
      end

      context "when there are no activities" do
        subject { described_class.new(activities: [], include_breakdown: breakdown) }

        it "returns an empty array" do
          expect(subject.headers).to eql []
          expect(subject.rows).to eql []
        end
      end

      describe "#last_financial_quarter" do
        it "returns the last financial quarter in the set" do
          expect(subject.last_financial_quarter).to eql FinancialQuarter.new(2020, 4)
        end
      end
    end
  end

  private

  def value_for_header(header_name)
    values = subject.rows.fetch(@activity.id)
    values[subject.headers.index(header_name)]
  end

  def create_q1_2020_actual_and_adjustments_in_q1_report
    @actual = create(
      :actual,
      parent_activity: @activity,
      value: 100,
      financial_quarter: 1,
      financial_year: 2020,
    )
    create(
      :adjustment,
      :actual,
      parent_activity: @activity,
      value: 200,
      financial_quarter: 1,
      financial_year: 2020,
    )
    create(
      :adjustment,
      :actual,
      parent_activity: @activity,
      value: -100,
      financial_quarter: 1,
      financial_year: 2020,
    )
  end

  def create_q4_2020_actual_and_adjustments_in_q4_report
    create(
      :actual,
      parent_activity: @activity,
      value: 100,
      financial_quarter: 4,
      financial_year: 2020,
    )
    create(
      :adjustment,
      :actual,
      parent_activity: @activity,
      value: 200,
      financial_quarter: 4,
      financial_year: 2020,
    )
    create(
      :adjustment,
      :actual,
      parent_activity: @activity,
      value: -100,
      financial_quarter: 4,
      financial_year: 2020,
    )
  end

  def create_q1_2020_refund_and_adjustments_in_q1_report
    @refund = create(
      :refund,
      parent_activity: @activity,
      value: -200,
      financial_quarter: 1,
      financial_year: 2020,
    )
    create(
      :adjustment,
      :refund,
      parent_activity: @activity,
      value: 50,
      financial_quarter: 1,
      financial_year: 2020,
    )
    create(
      :adjustment,
      :refund,
      parent_activity: @activity,
      value: -200,
      financial_quarter: 1,
      financial_year: 2020,
    )
  end

  def create_q4_2020_refund_and_adjustments_in_q4_report
    create(
      :refund,
      parent_activity: @activity,
      value: -200,
      financial_quarter: 4,
      financial_year: 2020,
    )
    create(
      :adjustment,
      :refund,
      parent_activity: @activity,
      value: 100,
      financial_quarter: 4,
      financial_year: 2020,
    )
    create(
      :adjustment,
      :refund,
      parent_activity: @activity,
      value: -200,
      financial_quarter: 4,
      financial_year: 2020,
    )
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
