require "rails_helper"

RSpec.describe OutgoingTransfer do
  include_examples "has transfer fields" do
    subject { build(:outgoing_transfer) }
  end
end
