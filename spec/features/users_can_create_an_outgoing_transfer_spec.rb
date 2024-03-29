RSpec.feature "Partner organisation users can create a transfer" do
  let(:user) { create(:partner_organisation_user) }
  before { authenticate!(user: user) }
  after { logout }

  include_examples "creating a transfer" do
    let(:source_activity) { create(:project_activity, organisation: user.organisation) }
    let(:target_activity) { source_activity }
    let(:created_transfer) { OutgoingTransfer.last }
    let(:transfer_type) { "outgoing_transfer" }
  end
end
