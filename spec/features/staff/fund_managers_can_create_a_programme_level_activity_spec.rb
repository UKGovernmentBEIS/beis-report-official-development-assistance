RSpec.feature "Create a programme level activity" do
  let!(:organisation) { create(:organisation, name: "UKSA") }

  context "when the user is a fund_manager" do
    before { authenticate!(user: create(:fund_manager, organisation: organisation)) }

    scenario "successfully create a activity" do
      visit organisation_path(organisation)
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(I18n.t("page_content.organisation.button.create_programme"))

      fill_in_activity_form

      expect(page).to have_content I18n.t("form.programme.create.success")
    end
  end
end
