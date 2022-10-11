require "rails_helper"

RSpec.describe OutgoingTransfersController do
  it_behaves_like "a transfer controller" do
    let(:transfer) { create(:outgoing_transfer, source: activity) }
  end
end
