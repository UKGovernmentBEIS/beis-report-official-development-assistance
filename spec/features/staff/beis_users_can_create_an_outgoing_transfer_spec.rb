RSpec.feature "BEIS users can create an outgoing transfer" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  include_examples "creating a transfer" do
    let(:source_activity) { create(:programme_activity) }
    let(:created_transfer) { OutgoingTransfer.last }
    let(:transfer_type) { "outgoing_transfer" }
  end
end
