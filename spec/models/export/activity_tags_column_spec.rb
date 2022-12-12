RSpec.describe Export::ActivityTagsColumn do
  include Rails.application.routes.url_helpers

  before(:all) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.start
    @activities = create_list(:project_activity, 5)
  end

  after(:all) do
    DatabaseCleaner.clean
  end

  context "when there are activities" do
    subject { Export::ActivityTagsColumn.new(activities: @activities) }

    describe "#headers" do
      it "returns the header" do
        expect(subject.headers).to match_array(["Tags"])
      end
    end

    describe "#rows" do
      it "returns the activity's tags as pipe-separated text" do
        activity = @activities.first
        activity.update(tags: [1, 3])
        expect(subject.rows.fetch(activity.id)).to eq(["Ayrton Fund|Double-badged for ICF"])
      end

      it "returns the correct number of rows" do
        expect(subject.rows.count).to eq 5
      end
    end
  end

  context "when there are no activities" do
    subject { Export::ActivityTagsColumn.new(activities: nil) }

    describe "#headers" do
      it "returns the header" do
        expect(subject.headers).to eq ["Tags"]
      end
    end

    describe "#rows" do
      it "returns an empty hash" do
        expect(subject.rows).to eq({})
      end
    end
  end
end
