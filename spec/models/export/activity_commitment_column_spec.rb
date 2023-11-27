RSpec.describe Export::ActivityCommitmentColumn do
  describe "#headers" do
    it "returns an array that contains the header name of the column" do
      activities = []

      column = described_class.new(activities: activities)

      expect(column.headers).to eql ["Original Commitment"]
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
      context "when the activity has a commitment" do
        it "returns the activity ID and the value of the commitment" do
          commitment = double(Commitment, value: 100000.00)
          activity = double(Activity, commitment: commitment, id: "ACTIVITY_ID")
          activities = [activity]

          column = described_class.new(activities: activities)

          expect(column.rows.count).to eql 1
          expect(column.rows.first[0]).to eql "ACTIVITY_ID"
          expect(column.rows.first[1]).to eql 100000.00
        end
      end

      context "when the activity has no commitment" do
        it "returns the value as nil" do
          activity = double(Activity, commitment: nil, id: "ACTIVITY_ID")
          activities = [activity]

          column = described_class.new(activities: activities)

          expect(column.rows.count).to eql 1
          expect(column.rows.first[0]).to eql "ACTIVITY_ID"
          expect(column.rows.first[1]).to be_nil
        end
      end
    end
  end
end
