RSpec.feature "Partner organisation users can edit a transfer" do
  let(:user) { create(:partner_organisation_user) }
  before { authenticate!(user: user) }

  include_examples "editing a transfer" do
    let(:source_activity) { create(:project_activity, organisation: user.organisation) }
    let(:destination_activity) { create(:project_activity) }
    let(:report) { Report.for_activity(source_activity).create(state: "active") }

    let(:target_activity) { source_activity }

    let!(:transfer) { create(:outgoing_transfer, report: report, source: source_activity, destination: destination_activity) }

    let(:transfer_type) { "outgoing_transfer" }

    before do
      visit organisation_activity_transfers_path(source_activity.organisation, source_activity)
      find("a[href='#{edit_activity_outgoing_transfer_path(source_activity.id, transfer.id)}']").click
    end
  end
end
