require "rails_helper"

RSpec.describe SpendingBreakdownJob, type: :job do
  let(:requester) { double(:user) }
  let(:fund) { double(:fund) }

  describe "#perform" do
    before do
      allow(User).to receive(:find)
      allow(Fund).to receive(:new)
    end

    it "asks the user object for the user with a given id" do
      SpendingBreakdownJob.perform_now(requester_id: "user123", fund_id: double)

      expect(User).to have_received(:find).with("user123")
    end

    it "asks the fund object for the fund with a given id" do
      SpendingBreakdownJob.perform_now(requester_id: double, fund_id: "fund123")

      expect(Fund).to have_received(:new).with("fund123")
    end
  end
end
