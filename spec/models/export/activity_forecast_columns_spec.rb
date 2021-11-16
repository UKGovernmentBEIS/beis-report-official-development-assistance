RSpec.describe Export::ActivityForecastColumns do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @activity = create(:project_activity)
    other_activities = create_list(:project_activity, 4)

    @activities = [@activity] + other_activities

    q1_2018_report = create(
      :report,
      :approved,
      organisation: @activity.organisation,
      fund: @activity.associated_fund,
      financial_quarter: 1,
      financial_year: 2018
    )
    forecasts_for_report_from_table(q1_2018_report,
      <<~TABLE
        |financial_quarter|financial_year|value|
        |4                |2018          | 5000|
        |1                |2020          |10000|
        |4                |2020          | 5000|
        |1                |2021          |40000|
        |4                |2021          |20000|
      TABLE
    )

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
        |1                |2020          | 5000|
        |4                |2020          | 2500|
        |1                |2021          |20000|
        |4                |2021          |10000|
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
        |1                |2020          |10000|
        |4                |2020          | 5000|
        |1                |2021          |40000|
        |4                |2021          |20000|
      TABLE
    )
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  subject {
    Export::ActivityForecastColumns.new(
      activities: @activities,
      report: report,
      starting_financial_quarter: starting_financial_quarter
    )
  }

  context "when passed a report AND a starting_financial_quarter" do
    let(:report) { build(:report) }
    let(:starting_financial_quarter) { FinancialQuarter.new }

    it "raises an argument error" do
      expect {
        Export::ActivityForecastColumns.new(
          activities: @activities,
          report: report,
          starting_financial_quarter: starting_financial_quarter
        )
      }.to raise_error ArgumentError
    end
  end

  context "when no report or starting financial quarter is passed in" do
    let(:report) { nil }
    let(:starting_financial_quarter) { nil }

    describe "#headers" do
      it "includes the heading that describe the finances for the earliest forecast" do
        expect(subject.headers).to include("Forecast FQ4 2018-2019")
      end

      it "includes the heading that describe the finances for financial quarter FQ1 2021-2022" do
        expect(subject.headers).to include(
          "Forecast FQ1 2021-2022",
        )
      end

      it "includes the heading that describe the finances for financial quarter FQ4 2021-2022" do
        expect(subject.headers).to include(
          "Forecast FQ4 2021-2022",
        )
      end

      it "includes the headings that describe the finances for financial quarters inbetween" do
        expect(subject.headers).to include(
          "Forecast FQ2 2021-2022",
          "Forecast FQ3 2021-2022",
        )
      end
    end

    describe "#rows" do
      it "contains the financial data for earliest financial quarter" do
        expect(value_for_header("Forecast FQ4 2018-2019").to_s).to eql("5000.0")
      end

      it "contains the financial data for financial quarter 1 2021-2022" do
        expect(value_for_header("Forecast FQ1 2021-2022").to_s).to eql("40000.0")
      end

      it "contains the financial data for financial quarter 4 2021-2022" do
        expect(value_for_header("Forecast FQ4 2021-2022").to_s).to eql("20000.0")
      end

      it "contains a zero for the financial quarters inbetween in which there are no forecasts" do
        expect(value_for_header("Forecast FQ2 2021-2022").to_s).to eql "0"
        expect(value_for_header("Forecast FQ3 2021-2022").to_s).to eql "0"
      end

      it "includes a row for each acitvity" do
        expect(subject.rows.count).to eq(5)
      end
    end

    context "when there are no activities" do
      subject { Export::ActivityForecastColumns.new(activities: []) }

      it "returns an empty array" do
        expect(subject.headers).to eql []
        expect(subject.rows).to eql []
      end
    end
  end

  context "when a report is passed in" do
    let(:report) { create(:report, financial_quarter: 1, financial_year: 2019) }
    let(:starting_financial_quarter) { nil }

    describe "#headers" do
      it "incudes the heading that describe the finances for the finnacial quarter of the report" do
        expect(subject.headers).to include("Forecast FQ2 2019-2020")
      end

      it "includes the heading that describe the finances for financial quarter FQ1 2021-2022" do
        expect(subject.headers).to include(
          "Forecast FQ1 2021-2022",
        )
      end

      it "includes the heading that describe the finances for financial quarter FQ4 2021-2022" do
        expect(subject.headers).to include(
          "Forecast FQ4 2021-2022",
        )
      end

      it "includes the headings that describe the finances for financial quarters inbetween" do
        expect(subject.headers).to include(
          "Forecast FQ2 2021-2022",
          "Forecast FQ3 2021-2022",
        )
      end

      it "contains the the forecast for Q1 2021-2022 as provided in the given report" do
        expect(subject.headers).not_to include("Forecast FQ4 2018-2019")
      end
    end

    describe "#rows" do
      it "contains the financial data for financial quarter of the report" do
        expect(value_for_header("Forecast FQ1 2019-2020").to_s).to eql("0")
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

      it "includes a row for each acitvity" do
        expect(subject.rows.count).to eq(5)
      end
    end

    context "when there are no activities" do
      subject { Export::ActivityForecastColumns.new(activities: []) }

      it "returns an empty array" do
        expect(subject.headers).to eql []
        expect(subject.rows).to eql []
      end
    end

    context "when the Q1 2020-2021 report is passed in" do
      let(:report) { create(:report, financial_quarter: 1, financial_year: 2020) }

      describe "#rows_for_first_financial_quarter" do
        it "returns the rows for the first column in the set (Q1 2020-2021)" do
          first_column_of_forecasts = subject.rows_for_first_financial_quarter
          activity_value = first_column_of_forecasts.fetch(@activity.id)

          expect(activity_value).to eq BigDecimal(10_000)
          expect(first_column_of_forecasts.count).to eq 5
        end
      end
    end
  end

  context "when there is a starting financial quarter" do
    let(:starting_financial_quarter) { FinancialQuarter.new(2020, 1) }
    let(:report) { nil }

    describe "#headers" do
      it "does not include the heading for the quarter before the starting one" do
        expect(subject.headers).not_to include("Forecast FQ4 2019-2020")
      end

      it "does include the heading for the starting quarter" do
        expect(subject.headers).to include("Forecast FQ1 2020-2021")
      end
    end

    describe "#rows" do
      it "includes the latest value for the starting quarter" do
        expect(value_for_header("Forecast FQ1 2020-2021").to_s).to eql("10000.0")
      end

      it "contains the financial data for financial quarter 4 2021-2022" do
        expect(value_for_header("Forecast FQ4 2021-2022").to_s).to eql("20000.0")
      end
    end

    context "when #rows is called multiple times" do
      let(:starting_financial_quarter) { nil }
      let(:report) { nil }

      before do
        forecast_overview_double = double(latest_values: [])
        allow(ForecastOverview).to receive(:new).and_return(forecast_overview_double)

        3.times { subject.rows }
      end

      it "gets the forecast overview only once" do
        expect(ForecastOverview)
          .to have_received(:new)
          .once
      end
    end
  end
end
