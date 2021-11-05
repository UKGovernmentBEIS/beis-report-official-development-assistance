RSpec.describe Export::Report do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start

    @report = create(:report)
    @activities = create_list(:project_activity, 5)
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
      finder_double = double(Activity::ProjectsForReportFinder, call: @activities, sort_by: @activities)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    describe "#headers" do
      it "returns the headers" do
        expect(subject.headers).to match_array(@headers_for_report)
      end
    end

    describe "#rows" do
      it "returns the rows" do
        rows = subject.rows
        expect(rows.count).to eq @activities.count
        expect(rows.fetch(@activities.first.id)).to include(@activities.first.roda_identifier)
        expect(rows.fetch(@activities.last.id)).to include(@activities.last.roda_identifier)
      end
    end
  end

  context "when there are activities" do
    subject { described_class.new(report: @report) }

    before do
      finder_double = double(Activity::ProjectsForReportFinder, call: [], sort_by: [])
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder_double)
    end

    describe "#headers" do
      it "returns the headers" do
        expect(subject.headers).to match_array(@headers_for_report)
      end
    end

    describe "#rows" do
      it "returns no rows" do
        expect(subject.rows.count).to eq 0
      end
    end
  end
end
