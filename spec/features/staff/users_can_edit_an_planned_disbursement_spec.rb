RSpec.describe "Users can edit a planned disbursement" do
  context "when signed in as a deivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "they can edit a planned disbursement" do
      organisation = user.organisation
      project = create(:project_activity, organisation: user.organisation)
      planned_disbursement = create(:planned_disbursement, parent_activity: project)
      visit organisation_activity_path(organisation, project)

      within "##{planned_disbursement.id}" do
        click_on "Edit"
      end

      expect(page).to have_http_status(:success)

      fill_in "Receiving organisation", with: "An Organisation"
      click_button "Submit"

      expect(page).to have_content I18n.t("form.planned_disbursement.update.success")
      expect(page).to have_content "An Organisation"
    end
  end
end
