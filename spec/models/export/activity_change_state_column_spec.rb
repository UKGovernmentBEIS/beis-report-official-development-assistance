RSpec.describe Export::ActivityChangeStateColumn do
  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @new_activity = create(:project_activity)
    @changed_activity = create(:project_activity)
    @unchanged_activity = create(:project_activity)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "when there are rows" do
    let(:report) { build_stubbed(:report) }
    let(:activities) { [@new_activity, @changed_activity, @unchanged_activity] }

    before do
      changed_activities = double(ActiveRecord::Relation, pluck: [@changed_activity.id])
      allow(report).to receive(:activities_updated).and_return(changed_activities)

      new_activities = double(ActiveRecord::Relation, pluck: [@new_activity.id])
      allow(report).to receive(:new_activities).and_return(new_activities)

      finder = double(Activity::ProjectsForReportFinder, call: activities)
      allow(Activity::ProjectsForReportFinder).to receive(:new).and_return(finder)
    end

    subject { described_class.new(activities: activities, report: report) }

    describe "#headers" do
      it "returns the correct headers" do
        expect(subject.headers).to eq ["Change state"]
      end
    end

    describe "#rows" do
      it "returns nil when the activity is not in the report" do
        expect(subject.rows.fetch("activity-id-not-in-report", nil)).to be_nil
      end

      it "returns 'New' for an activity that was created in the report" do
        expect(subject.rows.fetch(@new_activity.id)).to match_array(["New"])
      end

      it "returns 'Changed' for an activity with changes to its attributes in the report" do
        expect(subject.rows.fetch(@changed_activity.id)).to match_array(["Changed"])
      end

      it "returns 'Unchanged' for an activity that neither applies" do
        expect(subject.rows.fetch(@unchanged_activity.id)).to match_array(["Unchanged"])
      end
    end
  end

  context "when there are no rows" do
    let(:report) { build_stubbed(:report) }
    let(:activities) { [] }
    subject { described_class.new(activities: activities, report: report) }

    describe "#headers" do
      it "returns the headers" do
        expect(subject.headers).to eq ["Change state"]
      end
    end

    describe "#rows" do
      it "returns an empty array" do
        expect(subject.rows).to eq []
      end
    end
  end
end
