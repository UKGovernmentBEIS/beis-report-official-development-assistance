require "rails_helper"

RSpec.describe OutgoingTransfer do
  include_examples "has transfer fields" do
    subject { build(:outgoing_transfer) }
  end

  describe "#destination_roda_identifier=" do
    let(:transfer) { build(:outgoing_transfer, destination: nil) }

    it "sets the source when the activity exists" do
      activity = create(:programme_activity)

      transfer.destination_roda_identifier = activity.roda_identifier

      expect(transfer.destination).to eq(activity)
    end

    it "does not set the source when the activity does not exist" do
      transfer.destination_roda_identifier = "ABC123"

      expect(transfer.destination).to eq(nil)
    end
  end

  describe "#destination_roda_identifier" do
    let(:activity) { build(:project_activity) }
    let(:transfer) { build(:outgoing_transfer, source: activity) }

    it "returns the activity's RODA identifier" do
      expect(transfer.destination_roda_identifier).to eq(activity.roda_identifier)
    end
  end
end
