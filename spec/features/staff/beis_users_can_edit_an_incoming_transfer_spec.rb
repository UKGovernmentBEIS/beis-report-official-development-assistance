RSpec.feature "BEIS users can edit a transfer" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  include_examples "editing a transfer" do
    let(:source_activity) { create(:programme_activity) }
    let(:destination_activity) { create(:programme_activity) }

    let(:target_activity) { destination_activity }

    let!(:transfer) { create(:incoming_transfer, source: source_activity, destination: destination_activity) }

    let(:transfer_type) { "incoming_transfer" }

    before do
      visit organisation_activity_transfers_path(target_activity.organisation, target_activity)
      find("a[href='#{edit_activity_incoming_transfer_path(target_activity.id, transfer.id)}']").click
    end
  end
end
