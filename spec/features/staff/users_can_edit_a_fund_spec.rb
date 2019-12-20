RSpec.feature "Users can edit a fund" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:organisation)
      fund = create(:fund, organisation: organisation)
      page.set_rack_session(userinfo: nil)
      visit edit_organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is an administrator" do
    scenario "the user can edit a fund" do
      organisation = create(:organisation)
      fund = create(:fund, organisation: organisation)
      user = create(:administrator)
      authenticate!(user: user)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

      click_on(organisation.name)
      click_on(fund.name)

      within(".fund_name") do
        click_on(I18n.t("generic.link.edit"))
      end

      fill_in "fund[name]", with: "My New Fund name"
      click_button I18n.t("generic.button.submit")
      expect(page).to have_content("My New Fund name")
    end
  end

  context "when the user is a delivery partner" do
    scenario "the user cannot edit a fund" do
      organisation = create(:organisation)
      fund = create(:fund, organisation: organisation)
      user = create(:delivery_partner, organisations: [organisation])
      authenticate!(user: user)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

      click_on(organisation.name)
      click_on(fund.name)

      expect(page).not_to have_content(I18n.t("generic.link.edit"))
    end
  end
end
