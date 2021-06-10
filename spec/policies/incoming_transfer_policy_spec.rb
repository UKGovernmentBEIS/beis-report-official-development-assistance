require "rails_helper"

RSpec.describe IncomingTransferPolicy do
  include_examples "transfer policy" do
    let(:transfer) { create(:incoming_transfer, destination: activity) }
  end
end
