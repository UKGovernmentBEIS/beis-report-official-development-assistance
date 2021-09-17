RSpec.describe Report::Export do
  subject { described_class.new(reports: reports, export_type: export_type) }

  let(:report) { build(:report) }
  let(:reports) { [report] }
  let(:export_type) { :single }

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
        "ACT FQ4 2018-2019",
        "ACT FQ1 2019-2020",
        "ACT FQ2 2019-2020",
        "ACT FQ3 2019-2020",
        "ACT FQ4 2019-2020",
        "ACT FQ1 2020-2021",
        "ACT FQ2 2020-2021",
        "ACT FQ3 2020-2021",
        "ACT FQ4 2020-2021",
        "ACT FQ1 2021-2022",
        "ACT FQ2 2021-2022"
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

  context "when the export_type is all" do
    let(:reports) { reports_with_financial_quarters.append(report_without_financial_quarter) }

    let(:reports_with_financial_quarters) { build_list(:report, 3) }
    let(:report_without_financial_quarter) { build(:report, financial_year: nil, financial_quarter: nil) }
    let(:export_type) { :all }

    describe "#rows" do
      let(:activities) { build_list(:project_activity, 6) }
      let(:projects_for_report_stub) { double("Activity::ProjectsForReportFinder", call: activities) }

      it "maps all the reports and their activities to the row" do
        activities = []

        expect(Activity::ProjectsForReportFinder).to_not receive(:new).with(report: report_without_financial_quarter, scope: Activity.all)

        reports_with_financial_quarters.each do |report|
          report_presenter = ReportPresenter.new(report)
          report_activities = build_list(:project_activity, 2)
          projects_for_report = double("Activity::ProjectsForReportFinder", call: report_activities)

          expect(Activity::ProjectsForReportFinder).to receive(:new).with(report: report, scope: Activity.all).and_return(projects_for_report)
          allow(ReportPresenter).to receive(:new).and_return(report_presenter)

          report_activities.each do |activity|
            stub = double("Report::Export::Row")

            expect(Report::Export::Row).to receive(:new).with(
              activity: activity,
              report_presenter: report_presenter,
              previous_report_quarters: an_instance_of(Array),
              following_report_quarters: an_instance_of(Array),
            ).and_return(stub)

            expect(stub).to receive(:call).and_return([activity.title])
          end

          activities += report_activities
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

    let(:actual_index) { Report::Export::Row::ACTIVITY_HEADERS.count }
    let(:forecast_index) { actual_index + previous_report_quarters.count }

    let(:actual_columns) { subject.call.slice(actual_index, previous_report_quarters.count) }
    let(:forecast_columns) { subject.call.slice(forecast_index, following_report_quarters.count) }
    let(:variance_columns) { subject.call.slice(-5, 5) }

    subject do
      described_class.new(
        activity: activity,
        report_presenter: report_presenter,
        previous_report_quarters: previous_report_quarters,
        following_report_quarters: following_report_quarters
      )
    end

    before do
      allow(ActivityPresenter).to receive(:new).and_return(activity_presenter)
    end

    it "includes the activity data" do
      expect(subject.call).to include(activity.roda_identifier)
    end

    it "includes the actuals for the previous quarters" do
      actuals = [
        build(:actual, financial_quarter: 1, financial_year: 2020, value: 20),
        build(:actual, financial_quarter: 2, financial_year: 2020, value: 40),
        build(:actual, financial_quarter: 3, financial_year: 2020, value: 80),
      ]

      all_quarters = ActualOverview::AllQuarters.new(actuals)
      actual_overview = double("ActualOverview", all_quarters: all_quarters, value_for_report_quarter: 0)
      expect(ActualOverview).to receive(:new).with(activity_presenter, report_presenter).at_least(:once).and_return(actual_overview)

      expect(actual_columns).to eq(["20.00", "40.00", "80.00", "0.00"])
    end

    it "includes the forecasts for the next quarters" do
      all_quarters = double("ForecastOverview::AllQuarters")
      snapshot = double("ForecastOverview::Snapshot", all_quarters: all_quarters, value_for_report_quarter: 0)
      forecast_overview = double("ForecastOverview")

      expect(ForecastOverview).to receive(:new).with(activity_presenter).at_least(:once).and_return(forecast_overview)
      expect(forecast_overview).to receive(:snapshot).with(report_presenter).at_least(:once).and_return(snapshot)

      expect(all_quarters).to receive(:value_for).with(**following_report_quarters[0]).and_return(100)
      expect(all_quarters).to receive(:value_for).with(**following_report_quarters[1]).and_return(40)
      expect(all_quarters).to receive(:value_for).with(**following_report_quarters[2]).and_return(80)
      expect(all_quarters).to receive(:value_for).with(**following_report_quarters[3]).and_return(90)

      expect(forecast_columns).to eq(["100.00", "40.00", "80.00", "90.00"])
    end

    it "includes the variance data" do
      fund = Fund.new("1")
      comment = build(:comment, comment: "Comment")
      extending_organisation = build(:delivery_partner_organisation)

      expect(activity_presenter).to receive(:variance_for_report_financial_quarter).with(report: report_presenter).and_return(100.00)
      expect(activity_presenter).to receive(:comment_for_report).with(report_id: report_presenter.id).and_return(comment)
      expect(activity_presenter).to receive(:source_fund).and_return(fund)
      expect(activity_presenter).to receive(:extending_organisation).and_return(extending_organisation)
      expect(activity_presenter).to receive(:link_to_roda).and_return("http://example.com")

      expect(variance_columns).to eq([
        100.00,
        comment.comment,
        fund.name,
        extending_organisation.beis_organisation_reference,
        "http://example.com",
      ])
    end
  end
end
