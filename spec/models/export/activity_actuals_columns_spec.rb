RSpec.describe Export::ActivityActualsColumns do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @activity = create(:project_activity)
    other_activities = create_list(:project_activity, 4)

    @activities = [@activity] + other_activities

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
        | Refund    |q1    | q1             | -200|
        | Adj. Ref. |q2    | q1             |   50|
        | Adj. Ref. |q2    | q1             | -200|
        | Actual    |q3    | q3             |  100|
        | Refund    |q3    | q3             | -200|
        | Adj. Act. |q4    | q3             |  200|
        | Adj. Act. |q4    | q3             | -100|
        | Adj. Ref. |q4    | q3             |  100|
        | Adj. Ref. |q4    | q3             | -200|
        | Actual    |q4    | q4             |  300|
      TABLE
    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject { described_class.new(activities: @activities, include_breakdown: breakdown, report: report) }

  context "when a breakdown is not requested" do
    let(:breakdown) { false }
    let(:report) { nil }

    describe "#headers" do
      it "contains the headers for financial quarters in which there is actual spend" do
        expect(subject.headers).to match_array(
          [
            "Actual net FQ1 2020-2021",
            "Actual net FQ2 2020-2021",
            "Actual net FQ3 2020-2021",
            "Actual net FQ4 2020-2021",
          ]
        )
      end
    end

    describe "#rows" do
      it "contains the financial data for FQ1 2020-2021 including later adjustments" do
        expect(value_for_header("Actual net FQ1 2020-2021"))
          .to eq BigDecimal(100 + 200 + -100 + -200 + 50 + -200)
      end

      it "contains the financial data for FQ3 2020-2021 including later adjustments" do
        expect(value_for_header("Actual net FQ3 2020-2021"))
          .to eq BigDecimal(100 + 200 + -100 + -200 + 100 + -200)
      end

      it "contains the financial data for FQ4 2020-2021" do
        expect(value_for_header("Actual net FQ4 2020-2021"))
          .to eq BigDecimal(300)
      end

      it "contains zero values for the financial quarters inbetween" do
        expect(value_for_header("Actual net FQ2 2020-2021")).to eq 0
      end

      it "includes a row for each activity" do
        expect(subject.rows.count).to eq(5)
      end
    end

    context "when the Q3 2020-2021 report is passed" do
      let(:report) { create(:report, financial_quarter: 3, financial_year: 2020) }

      describe "#headers" do
        it "contains the headers for financial  quarters up to and including the report" do
          expect(subject.headers).to match_array(
            [
              "Actual net FQ1 2020-2021",
              "Actual net FQ2 2020-2021",
              "Actual net FQ3 2020-2021",
            ]
          )
        end

        it "does not contain headers for the financial quarters after the report" do
          expect(subject.headers).not_to include("Actual net FQ4 2020-201")
        end
      end

      describe "#rows" do
        it "contains the financial data for FQ1 2020-2021 as of Q3 2020-2021" do
          expect(value_for_header("Actual net FQ1 2020-2021"))
            .to eq BigDecimal(100 + 200 + -100 + -200 + 50 + -200)
        end

        it "contains the financial data for FQ3 2020-2021 as of Q3 2020-2021" do
          expect(value_for_header("Actual net FQ3 2020-2021"))
            .to eq BigDecimal(100 + -200)
        end

        it "contains zero values for the financial quarters inbetween" do
          expect(value_for_header("Actual net FQ2 2020-2021")).to eq 0
        end

        it "includes a row for each activity" do
          expect(subject.rows.count).to eq(5)
        end
      end
    end
  end

  context "when a breakdown is requested" do
    let(:breakdown) { true }
    let(:report) { nil }

    describe "#headers" do
      it "contains the headings that describe the finances for FQ1 2020-2021" do
        expect(subject.headers).to include(
          "Actual spend FQ1 2020-2021",
          "Refund FQ1 2020-2021",
          "Actual net FQ1 2020-2021",
        )
      end

      it "contains the headings that describe the finances for FQ3 2020-2021" do
        expect(subject.headers).to include(
          "Actual spend FQ3 2020-2021",
          "Refund FQ3 2020-2021",
          "Actual net FQ3 2020-2021",
        )
      end

      it "contains the headings that describe the finances for FQ4 2020-2021" do
        expect(subject.headers).to include(
          "Actual spend FQ4 2020-2021",
          "Refund FQ4 2020-2021",
          "Actual net FQ4 2020-2021",
        )
      end

      it "contains the headings that describe the finances for financial quarters inbetween" do
        expect(subject.headers).to include(
          "Actual spend FQ2 2020-2021",
          "Refund FQ2 2020-2021",
          "Actual net FQ2 2020-2021",
        )
      end
    end

    describe "#rows" do
      it "contains the financial data for FQ1 2020-2021" do
        aggregate_failures do
          expect(value_for_header("Actual spend FQ1 2020-2021"))
            .to eq BigDecimal(100 + 200 + -100)
          expect(value_for_header("Refund FQ1 2020-2021"))
            .to eq BigDecimal(-200 + 50 + -200)
          expect(value_for_header("Actual net FQ1 2020-2021"))
            .to eq BigDecimal(100 + 200 + -100 + -200 + 50 + -200)
        end
      end

      it "contains the financial data for FQ3 2020-2021" do
        aggregate_failures do
          expect(value_for_header("Actual spend FQ3 2020-2021"))
            .to eq BigDecimal(100 + 200 + -100)
          expect(value_for_header("Refund FQ3 2020-2021"))
            .to eq BigDecimal(-200 + 100 + -200)
          expect(value_for_header("Actual net FQ3 2020-2021"))
            .to eq BigDecimal(100 + 200 + -100 + -200 + 100 + -200)
        end
      end

      it "contains the financial data for FQ4 2020-2021" do
        aggregate_failures do
          expect(value_for_header("Actual spend FQ4 2020-2021"))
            .to eq BigDecimal(300)
          expect(value_for_header("Refund FQ4 2020-2021"))
            .to eq 0
          expect(value_for_header("Actual net FQ4 2020-2021"))
            .to eq BigDecimal(300)
        end
      end

      it "contains zero values for the financial quarters inbetween" do
        aggregate_failures do
          expect(value_for_header("Actual spend FQ2 2020-2021")).to eq 0
          expect(value_for_header("Refund FQ2 2020-2021")).to eq 0
          expect(value_for_header("Actual net FQ2 2020-2021")).to eq 0
        end
      end

      it "includes a row for each activity" do
        expect(subject.rows.count).to eq(5)
      end
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

  private

  def value_for_header(header_name)
    values = subject.rows.fetch(@activity.id)
    values[subject.headers.index(header_name)]
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
