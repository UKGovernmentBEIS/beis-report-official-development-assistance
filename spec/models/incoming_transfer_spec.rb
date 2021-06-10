require "rails_helper"

RSpec.describe IncomingTransfer do
  include_examples "has transfer fields" do
    subject { build(:incoming_transfer) }
  end
end
