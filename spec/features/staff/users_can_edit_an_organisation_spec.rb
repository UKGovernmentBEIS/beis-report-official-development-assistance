RSpec.feature "Users can edit an organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:organisation)
      page.set_rack_session(userinfo: nil)
      visit edit_organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is an administrator" do
    scenario "they can edit an organisation" do
      organisation = create(:organisation)
      user = create(:administrator)
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name
      click_link I18n.t("page_content.organisation.button.edit")

      expect(page).to have_content(I18n.t("page_title.organisation.edit"))
      fill_in "organisation[name]", with: "My New Organisation"
      select "Government", from: "organisation[organisation_type]"
      select "Czech", from: "organisation[language_code]"
      select "Zloty", from: "organisation[default_currency]"
      click_button I18n.t("generic.button.submit")
      expect(page).to have_content I18n.t("form.organisation.update.success")
    end

    scenario "presence validation works as expected" do
      organisation = create(:organisation)
      user = create(:administrator)
      authenticate!(user: user)

      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link organisation.name
      click_link I18n.t("page_content.organisation.button.edit")

      expect(page).to have_content(I18n.t("page_title.organisation.edit"))
      fill_in "organisation[name]", with: "My New Organisation"

      click_button I18n.t("generic.button.submit")
      expect(page).to_not have_content I18n.t("form.organisation.update.success")
      expect(page).to have_content "can't be blank"
    end
  end

  context "when the user is a delivery partner" do
    context "that belongs to the organisation" do
      scenario "they can edit an organisation" do
        organisation = create(:organisation)
        user = create(:delivery_partner, organisations: [organisation])
        authenticate!(user: user)

        visit dashboard_path
        click_link I18n.t("page_content.dashboard.button.manage_organisations")
        click_link organisation.name
        click_link I18n.t("page_content.organisation.button.edit")

        expect(page).to have_content(I18n.t("page_title.organisation.edit"))
        fill_in "organisation[name]", with: "My New Organisation"
        select "Government", from: "organisation[organisation_type]"
        select "Czech", from: "organisation[language_code]"
        select "Zloty", from: "organisation[default_currency]"
        click_button I18n.t("generic.button.submit")
        expect(page).to have_content I18n.t("form.organisation.update.success")
      end
    end

    context "that does NOT belong to the organisation" do
      scenario "they cannot access the organisations page" do
        organisation = create(:organisation)
        user = create(:delivery_partner, organisations: [])
        authenticate!(user: user)

        visit dashboard_path
        click_link I18n.t("page_content.dashboard.button.manage_organisations")
        expect(page).not_to have_content(organisation.name)

        expect(page).to have_no_content(I18n.t("page_content.organisations.link.edit"))
      end

      scenario "shows the 'unauthorised' error message to the user" do
        organisation = create(:organisation)
        user = create(:delivery_partner, organisations: [])
        authenticate!(user: user)

        visit edit_organisation_path(organisation)

        expect(page).to have_content(I18n.t("pundit.default"))
        expect(page).to have_http_status(:unauthorized)
      end
    end
  end
end
