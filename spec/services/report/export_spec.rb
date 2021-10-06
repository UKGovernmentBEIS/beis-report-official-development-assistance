RSpec.describe Report::Export do
  subject { described_class.new(report: report) }

  let(:report) { build(:report) }

  describe "#headers" do
    before do
      report.financial_year = 2021
      report.financial_quarter = 2
    end

    it "includes the activity headers" do
      expect(subject.headers).to include(*Report::Export::Row::ACTIVITY_HEADERS.keys)
    end

    it "includes the previous twelve quarters" do
      expect(subject.headers).to include(
        "ACT FQ3 2018-2019",
        "REFUND FQ3 2018-2019",
        "ACT FQ4 2018-2019",
        "REFUND FQ4 2018-2019",
        "ACT FQ1 2019-2020",
        "REFUND FQ1 2019-2020",
        "ACT FQ2 2019-2020",
        "REFUND FQ2 2019-2020",
        "ACT FQ3 2019-2020",
        "REFUND FQ3 2019-2020",
        "ACT FQ4 2019-2020",
        "REFUND FQ4 2019-2020",
        "ACT FQ1 2020-2021",
        "REFUND FQ1 2020-2021",
        "ACT FQ2 2020-2021",
        "REFUND FQ2 2020-2021",
        "ACT FQ3 2020-2021",
        "REFUND FQ3 2020-2021",
        "ACT FQ4 2020-2021",
        "REFUND FQ4 2020-2021",
        "ACT FQ1 2021-2022",
        "REFUND FQ1 2021-2022",
        "ACT FQ2 2021-2022",
        "REFUND FQ2 2021-2022"
      )
    end

    it "includes the next twenty quarters" do
      expect(subject.headers).to include(
        "FC FQ2 2021-2022",
        "FC FQ3 2021-2022",
        "FC FQ4 2021-2022",
        "FC FQ1 2022-2023",
        "FC FQ2 2022-2023",
        "FC FQ3 2022-2023",
        "FC FQ4 2022-2023",
        "FC FQ1 2023-2024",
        "FC FQ2 2023-2024",
        "FC FQ3 2023-2024",
        "FC FQ4 2023-2024",
        "FC FQ1 2024-2025",
        "FC FQ2 2024-2025",
        "FC FQ3 2024-2025",
        "FC FQ4 2024-2025",
        "FC FQ1 2025-2026",
        "FC FQ2 2025-2026",
        "FC FQ3 2025-2026",
        "FC FQ4 2025-2026",
        "FC FQ1 2026-2027",
      )
    end

    it "includes the variances" do
      expect(subject.headers).to include(
        "VAR FQ2 2021-2022",
        "Comment",
        "Source fund",
        "Delivery partner short name",
        "Link to activity in RODA"
      )
    end
  end

  describe "#rows" do
    let(:activities) { build_list(:project_activity, 6) }
    let(:projects_for_report_stub) { double("Activity::ProjectsForReportFinder", call: activities) }
    let(:report_presenter) { ReportPresenter.new(report) }

    before do
      allow(Activity::ProjectsForReportFinder).to receive(:new).with(report: report, scope: Activity.all).and_return(projects_for_report_stub)
      allow(ReportPresenter).to receive(:new).and_return(report_presenter)
    end

    it "maps all the activities to Row class" do
      activities.each do |activity|
        stub = double("Report::Export::Row")
        expect(Report::Export::Row).to receive(:new).with(
          activity: activity,
          report_presenter: report_presenter,
          previous_report_quarters: an_instance_of(Array),
          following_report_quarters: an_instance_of(Array),
          actual_quarters: an_instance_of(Actual::Overview::AllQuarters),
          refund_quarters: an_instance_of(Refund::Overview::AllQuarters),
        ).and_return(stub)
        expect(stub).to receive(:call).and_return([activity.title])
      end

      expect(subject.rows).to match_array([
        [activities[0].title],
        [activities[1].title],
        [activities[2].title],
        [activities[3].title],
        [activities[4].title],
        [activities[5].title],
      ])
    end
  end

  describe "#filename" do
    let(:presenter) { double("ReportPresenter", filename_for_report_download: filename) }
    let(:filename) { "foo.csv" }

    it "returns the filename from the presenter" do
      expect(ReportPresenter).to receive(:new).and_return(presenter)

      expect(subject.filename).to eq(filename)
    end
  end

  describe Report::Export::Row do
    # The row generates URLs, so we need to make sure the objects have UUIDs
    let(:organisation) { build(:delivery_partner_organisation, id: SecureRandom.uuid) }
    let(:activity) { build(:project_activity, id: SecureRandom.uuid, organisation: organisation) }

    let(:report_presenter) { ReportPresenter.new(build(:report)) }
    let(:activity_presenter) { ActivityPresenter.new(activity) }

    let(:previous_report_quarters) do
      [
        FinancialQuarter.new(2020, 1),
        FinancialQuarter.new(2020, 2),
        FinancialQuarter.new(2020, 3),
        FinancialQuarter.new(2020, 4),
      ]
    end
    let(:following_report_quarters) do
      [
        FinancialQuarter.new(2021, 1),
        FinancialQuarter.new(2021, 2),
        FinancialQuarter.new(2021, 3),
        FinancialQuarter.new(2021, 4),
      ]
    end

    let(:actuals) do
      [
        Actual.new(financial_quarter: 1, financial_year: 2020, value: 20, parent_activity: activity),
        Actual.new(financial_quarter: 2, financial_year: 2020, value: 40, parent_activity: activity),
        Actual.new(financial_quarter: 3, financial_year: 2020, value: 80, parent_activity: activity),
      ]
    end

    let(:refunds) do
      [
        Refund.new(financial_quarter: 1, financial_year: 2020, value: -5, parent_activity: activity),
        Refund.new(financial_quarter: 2, financial_year: 2020, value: -10, parent_activity: activity),
      ]
    end

    let(:actual_quarters) { Actual::Overview::AllQuarters.new(actuals) }
    let(:refund_quarters) { Refund::Overview::AllQuarters.new(refunds) }

    let(:actual_index) { Report::Export::Row::ACTIVITY_HEADERS.count }
    let(:forecast_index) { actual_index + previous_report_quarters.count }

    subject do
      described_class.new(
        activity: activity,
        report_presenter: report_presenter,
        previous_report_quarters: previous_report_quarters,
        following_report_quarters: following_report_quarters,
        actual_quarters: actual_quarters,
        refund_quarters: refund_quarters,
      )
    end

    before do
      allow(ActivityPresenter).to receive(:new).and_return(activity_presenter)
    end

    it "includes the activity data" do
      expect(subject.activity_data).to include(activity.roda_identifier)
    end

    context "financial data" do
      let(:forecast_quarters) { double("ForecastOverview::AllQuarters") }
      let(:forecast_snapshot) { double("ForecastOverview::Snapshot", all_quarters: forecast_quarters, value_for_report_quarter: 0) }
      let(:forecast_overview) { double("ForecastOverview") }
      let(:fund) { Fund.new(1) }
      let(:extending_organisation) { build(:delivery_partner_organisation) }

      it "includes the actuals and refunds for the previous quarters" do
        expect(subject.previous_quarter_actuals_and_refunds).to eq(["20.00", "-5.00", "40.00", "-10.00", "80.00", "0.00", "0.00", "0.00"])
      end

      it "includes the forecasts for the next quarters" do
        expect(ForecastOverview).to receive(:new).with(activity_presenter).at_least(:once).and_return(forecast_overview)
        expect(forecast_overview).to receive(:snapshot).with(report_presenter).at_least(:once).and_return(forecast_snapshot)

        expect(forecast_quarters).to receive(:value_for).with(**following_report_quarters[0]).at_least(:once).and_return(100)
        expect(forecast_quarters).to receive(:value_for).with(**following_report_quarters[1]).at_least(:once).and_return(40)
        expect(forecast_quarters).to receive(:value_for).with(**following_report_quarters[2]).at_least(:once).and_return(80)
        expect(forecast_quarters).to receive(:value_for).with(**following_report_quarters[3]).at_least(:once).and_return(90)

        expect(subject.next_quarter_forecasts).to eq(["100.00", "40.00", "80.00", "90.00"])
      end

      it "includes the variance data" do
        comments = [build(:comment, comment: "First comment"), build(:comment, comment: "Additional content")]

        expect(ForecastOverview).to receive(:new).with(activity_presenter).at_least(:once).and_return(forecast_overview)
        expect(forecast_overview).to receive(:snapshot).with(report_presenter).at_least(:once).and_return(forecast_snapshot)

        expect(forecast_quarters).to receive(:value_for).with(**report.own_financial_quarter).and_return(100)
        expect(actual_quarters).to receive(:value_for).with(activity: activity, **report.own_financial_quarter).and_return(120)

        expect(activity_presenter).to receive(:comments_for_report).with(report_id: report_presenter.id).and_return(comments)
        expect(activity_presenter).to receive(:source_fund).and_return(fund)
        expect(activity_presenter).to receive(:extending_organisation).and_return(extending_organisation)
        expect(activity_presenter).to receive(:link_to_roda).and_return("http://example.com")

        expect(subject.variance_data).to eq([
          -20.00,
          comments.map(&:comment).join("\n"),
          fund.name,
          extending_organisation.beis_organisation_reference,
          "http://example.com",
        ])
      end

      it "handles the variance when there are no comments" do
        expect(ForecastOverview).to receive(:new).with(activity_presenter).at_least(:once).and_return(forecast_overview)
        expect(forecast_overview).to receive(:snapshot).with(report_presenter).at_least(:once).and_return(forecast_snapshot)

        expect(forecast_quarters).to receive(:value_for).with(**report.own_financial_quarter).and_return(100)
        expect(actual_quarters).to receive(:value_for).with(activity: activity, **report.own_financial_quarter).and_return(120)

        expect(activity_presenter).to receive(:comments_for_report).with(report_id: report_presenter.id).and_return([])
        expect(activity_presenter).to receive(:source_fund).and_return(fund)
        expect(activity_presenter).to receive(:extending_organisation).and_return(extending_organisation)
        expect(activity_presenter).to receive(:link_to_roda).and_return("http://example.com")

        expect(subject.variance_data).to eq([
          -20.00,
          "",
          fund.name,
          extending_organisation.beis_organisation_reference,
          "http://example.com",
        ])
      end
    end
  end
end
