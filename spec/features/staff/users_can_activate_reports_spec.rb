RSpec.feature "Users can activate reports" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    let(:organisation) { create(:delivery_partner_organisation, users: build_list(:administrator, 3)) }

    before do
      authenticate!(user: beis_user)
    end

    context "when the report is already active" do
      scenario "it cannot be activated again" do
        report = create(:report, :active)

        visit report_path(report)

        expect(page).not_to have_link "Activate report"

        visit edit_report_state_path(report)

        expect(page.status_code).to eql 401
      end
    end
  end
end
