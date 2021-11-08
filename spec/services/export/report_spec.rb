RSpec.describe Export::Report do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @report = create(:report)
    @activity = create(:project_activity)
    @third_party_project = create(:third_party_project_activity, parent: @activity)
    @headers_for_report = Export::ActivityAttributesOrder.attributes_in_order.map { |att|
      I18n.t("activerecord.attributes.activity.#{att}")
    }
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "when there are activities" do
    subject { described_class.new(report: @report) }

    before do
      relation = Activity.where(level: ["project", "third_party_project"])
      finder_double = double(Activity::ProjectsForReportFinder, call: relation)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    describe "#headers" do
      it "returns the headers" do
        expect(subject.headers).to match_array(@headers_for_report)
      end
    end

    describe "#rows" do
      it "returns the rows ordered by level" do
        rows = subject.rows.to_a

        expect(rows.count).to eq 2
        expect(rows.first[1]).to include(@activity.roda_identifier)
        expect(rows.last[1]).to include(@third_party_project.roda_identifier)
      end
    end
  end

  context "when there are no activities" do
    subject { described_class.new(report: @report) }

    before do
      relation = Activity.none
      finder_double = double(Activity::ProjectsForReportFinder, call: relation)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    describe "#headers" do
      it "returns the headers" do
        headers = subject.headers

        expect(headers).to include(@headers_for_report.first)
        expect(headers).to include(@headers_for_report.last)
      end
    end

    describe "#rows" do
      it "returns no rows" do
        expect(subject.rows.count).to eq 0
      end
    end
  end
end
