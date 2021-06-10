require "rails_helper"

RSpec.describe OutgoingTransferPolicy do
  include_examples "transfer policy" do
    let(:transfer) { create(:outgoing_transfer, source: activity) }
  end
end
