RSpec.feature "BEIS users can create an incoming transfer" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }
  after { logout }

  include_examples "creating a transfer" do
    let(:target_activity) { create(:programme_activity) }
    let(:created_transfer) { IncomingTransfer.last }
    let(:transfer_type) { "incoming_transfer" }
  end
end
