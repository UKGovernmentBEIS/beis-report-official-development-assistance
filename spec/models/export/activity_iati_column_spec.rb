RSpec.describe Export::ActivityIatiColumn do
  describe "#headers" do
    it "returns an array that contains the header name of the column" do
      activities = []

      column = described_class.new(activities: activities)

      expect(column.headers).to eql ["Published on IATI"]
    end
  end

  describe "#rows" do
    context "when there are no activities" do
      it "returns an empty hash" do
        activities = []

        column = described_class.new(activities: activities)

        expect(column.rows).to be {}
      end
    end

    context "when there are activities" do
      context "when the activity is publishable to IATI" do
        it "returns the activity ID and yes" do
          activity = double(Activity, publish_to_iati: true, id: "ACTIVITY_ID")
          activities = [activity]

          column = described_class.new(activities: activities)

          expect(column.rows.count).to eql 1
          expect(column.rows.first[0]).to eql "ACTIVITY_ID"
          expect(column.rows.first[1]).to eql "Yes"
        end
      end

      context "when the activity is not publishable to IATI" do
        it "returns the activity ID and no" do
          activity = double(Activity, publish_to_iati: false, id: "ACTIVITY_ID")
          activities = [activity]

          column = described_class.new(activities: activities)

          expect(column.rows.count).to eql 1
          expect(column.rows.first[0]).to eql "ACTIVITY_ID"
          expect(column.rows.first[1]).to eql "No"
        end
      end
    end
  end
end
