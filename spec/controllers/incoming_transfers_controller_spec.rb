require "rails_helper"

RSpec.describe IncomingTransfersController do
  it_behaves_like "a transfer controller" do
    let(:transfer) { create(:incoming_transfer, destination: activity) }
  end
end
