RSpec.feature "Users can view an individual organisation" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:organisation)
      authenticate!(user: build_stubbed(:user))
      page.set_rack_session(userinfo: nil)
      visit organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is an administrator" do
    it "allows them to view the organisations page" do
      organisation = create(:organisation)
      user = create(:administrator)
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name

      expect(page).to have_content(I18n.t("page_title.organisation.show", name: organisation.name))
    end
  end

  context "when the user belongs to that organisation" do
    it "allows them to view the organisations page" do
      organisation = create(:organisation)
      user = create(:delivery_partner, organisations: [organisation])
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name

      expect(page).to have_content(I18n.t("page_title.organisation.show", name: organisation.name))
    end
  end

  context "when the user does NOT belong to that organisation" do
    it "does NOT provide a link to that organisation's page" do
      organisation = create(:organisation)
      user = create(:delivery_partner, organisations: [])
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      expect(page).not_to have_content(organisation.name)
    end

    it "shows the 'unauthorised' error message to the user" do
      organisation = create(:organisation)
      user = create(:delivery_partner, organisations: [])
      authenticate!(user: user)

      visit edit_organisation_path(organisation)

      expect(page).to have_content(I18n.t("pundit.default"))
      expect(page).to have_http_status(:unauthorized)
    end
  end

  scenario "can go back to the previous page" do
    organisation = create(:organisation)
    authenticate!(user: create(:administrator))

    visit organisation_path(organisation)

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(organisations_path)
  end
end
