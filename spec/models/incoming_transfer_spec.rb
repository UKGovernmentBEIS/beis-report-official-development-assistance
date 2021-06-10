require "rails_helper"

RSpec.describe IncomingTransfer do
  include_examples "has transfer fields" do
    subject { build(:incoming_transfer) }
  end

  describe "#source_roda_identifier=" do
    let(:transfer) { build(:incoming_transfer, source: nil) }

    it "sets the source when the activity exists" do
      activity = create(:programme_activity)

      transfer.source_roda_identifier = activity.roda_identifier

      expect(transfer.source).to eq(activity)
    end

    it "does not set the source when the activity does not exist" do
      transfer.source_roda_identifier = "ABC123"

      expect(transfer.source).to eq(nil)
    end
  end

  describe "#source_roda_identifier" do
    let(:activity) { build(:project_activity) }
    let(:transfer) { build(:incoming_transfer, source: activity) }

    it "returns the activity's RODA identifier" do
      expect(transfer.source_roda_identifier).to eq(activity.roda_identifier)
    end
  end
end
