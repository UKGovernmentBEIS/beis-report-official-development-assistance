RSpec.feature "Users can view an organisation" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:organisation)
      page.set_rack_session(userinfo: nil)
      visit organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund manager" do
    before do
      authenticate!(user: create(:fund_manager))
    end

    scenario "can see the organisation page" do
      organisation = create(:organisation)
      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name

      expect(page).to have_content(I18n.t("page_title.organisation.show", name: organisation.name))
    end

    scenario "can go back to the previous page" do
      organisation = create(:organisation)

      visit organisation_path(organisation)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisations_path)
    end
  end

  context "when the user is a delivery_partner that belongs to that organisation" do
    scenario "can see the organisation page" do
      organisation = create(:organisation)
      authenticate!(user: create(:delivery_partner, organisation: organisation))

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name

      expect(page).to have_content(I18n.t("page_title.organisation.show", name: organisation.name))
    end
  end
end
