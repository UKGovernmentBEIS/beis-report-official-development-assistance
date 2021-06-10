RSpec.feature "BEIS users can edit a transfer" do
  let(:user) { create(:beis_user) }
  before { authenticate!(user: user) }

  include_examples "editing a transfer" do
    let(:source_activity) { create(:programme_activity) }
    let(:destination_activity) { create(:programme_activity) }

    let!(:transfer) { create(:outgoing_transfer, source: source_activity, destination: destination_activity) }

    let(:transfer_type) { "outgoing_transfer" }

    before do
      visit organisation_activity_transfers_path(source_activity.organisation, source_activity)
      find("a[href='#{edit_activity_outgoing_transfer_path(source_activity.id, transfer.id)}']").click
    end
  end
end
