RSpec.describe Export::ActivityLinkColumn do
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
    subject { described_class.new(activities: @activities) }

    describe "#headers" do
      it "returns the header" do
        expect(subject.headers).to match_array(["Link to activity"])
      end
    end

    describe "#rows" do
      it "returns a link to the activity" do
        activity = @activities.first
        activity_link =
          Rails.application.routes.url_helpers.organisation_activity_details_url(
            activity.organisation,
            activity,
            host: ENV["DOMAIN"]
          ).to_s
        expect(subject.rows.fetch(activity.id)).to eq activity_link
      end

      it "returns the correct number of rows" do
        expect(subject.rows.count).to eq 5
      end
    end
  end

  context "when there are no activities" do
    subject { described_class.new(activities: nil) }

    describe "#headers" do
      it "returns the header" do
        expect(subject.headers).to eq ["Link to activity"]
      end
    end
    describe "#rows" do
      it "returns an empty array" do
        expect(subject.rows).to eq []
      end
    end
  end
end
