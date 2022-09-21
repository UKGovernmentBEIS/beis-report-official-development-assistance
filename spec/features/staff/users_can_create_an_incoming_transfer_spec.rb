RSpec.feature "Partner organisation users can create an incoming transfer" do
  let(:user) { create(:partner_organisation_user) }
  before { authenticate!(user: user) }

  include_examples "creating a transfer" do
    let(:target_activity) { create(:project_activity, organisation: user.organisation) }
    let(:created_transfer) { IncomingTransfer.last }
    let(:transfer_type) { "incoming_transfer" }
  end
end
