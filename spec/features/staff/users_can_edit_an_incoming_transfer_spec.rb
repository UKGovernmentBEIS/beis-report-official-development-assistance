RSpec.feature "BEIS users can edit an incoming transfer" do
  let(:user) { create(:delivery_partner_user) }
  before { authenticate!(user: user) }

  include_examples "editing a transfer" do
    let(:source_activity) { create(:project_activity) }
    let(:destination_activity) { create(:project_activity, organisation: user.organisation) }

    let(:report) { Report.for_activity(target_activity).create(state: "active") }

    let(:target_activity) { destination_activity }

    let!(:transfer) { create(:incoming_transfer, report: report, source: source_activity, destination: destination_activity) }

    let(:transfer_type) { "incoming_transfer" }

    before do
      visit organisation_activity_path(target_activity.organisation, target_activity)
      find("a[href='#{edit_activity_incoming_transfer_path(target_activity.id, transfer.id)}']").click
    end
  end
end
