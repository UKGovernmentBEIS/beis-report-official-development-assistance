RSpec.feature "Users can create a fund" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:organisation)
      authenticate!(user: build_stubbed(:user))
      page.set_rack_session(userinfo: nil)
      visit new_organisation_fund_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is an administrator" do
    scenario "they can create a fund" do
      organisation = create(:organisation)
      user = create(:administrator)
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name
      click_on I18n.t("page_title.fund.new")

      fill_in "fund[name]", with: "My Space Fund"
      click_button I18n.t("generic.button.submit")
      expect(page).to have_content I18n.t("form.fund.create.success")
    end

    scenario "presence validation works as expected" do
      organisation = create(:organisation)
      user = create(:administrator)
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name
      click_on I18n.t("page_title.fund.new")

      click_button I18n.t("generic.button.submit")
      expect(page).to_not have_content I18n.t("form.fund.create.success")
      expect(page).to have_content "can't be blank"
    end

    scenario "can go back to the previous page" do
      organisation = create(:organisation)
      user = create(:administrator)
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name
      click_on I18n.t("page_title.fund.new")

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_path(organisation.id))
    end
  end

  context "when the user is a delivery partner" do
    scenario "they cannot create a fund" do
      organisation = create(:organisation)
      user = create(:delivery_partner, organisations: [organisation])
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name

      expect(page).not_to have_content(I18n.t("page_title.fund.new"))
    end
  end
end
