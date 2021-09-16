RSpec.describe Report::Export do
  subject { described_class.new(reports: reports, export_type: export_type) }

  let(:export_activity_to_csv_stub) { double("ExportActivityToCsv") }
  let(:report) { build(:report) }
  let(:reports) { [report] }
  let(:export_type) { :single }

  describe "#headers" do
    it "returns the headers from ExportActivityToCsv" do
      headers = ["foo", "bar", "baz"]

      expect(ExportActivityToCsv).to receive(:new).with(report: report).and_return(export_activity_to_csv_stub)
      expect(export_activity_to_csv_stub).to receive(:headers).and_return(headers)

      expect(subject.headers).to eq(headers)
    end
  end

  describe "#rows" do
    let(:activities) { build_list(:project_activity, 6) }
    let(:projects_for_report_stub) { double("Activity::ProjectsForReportFinder", call: activities) }

    before do
      allow(Activity::ProjectsForReportFinder).to receive(:new).with(report: report, scope: Activity.all).and_return(projects_for_report_stub)
    end

    it "maps all the activities to ExportActivityToCsv" do
      activities.each do |activity|
        stub = double("ExportActivityToCsv")
        expect(ExportActivityToCsv).to receive(:new).with(activity: activity, report: report).and_return(stub)
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
    let(:reports) { build_list(:report, 3) }
    let(:export_type) { :all }

    describe "#rows" do
      let(:activities) { build_list(:project_activity, 6) }
      let(:projects_for_report_stub) { double("Activity::ProjectsForReportFinder", call: activities) }

      it "maps all the reports and their activities to ExportActivityToCsv" do
        activities = []

        reports.each do |report|
          report_activities = build_list(:project_activity, 2)
          projects_for_report = double("Activity::ProjectsForReportFinder", call: report_activities)
          expect(Activity::ProjectsForReportFinder).to receive(:new).with(report: report, scope: Activity.all).and_return(projects_for_report)

          report_activities.each do |activity|
            stub = double("ExportActivityToCsv")
            expect(ExportActivityToCsv).to receive(:new).with(activity: activity, report: report).and_return(stub)
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
end
