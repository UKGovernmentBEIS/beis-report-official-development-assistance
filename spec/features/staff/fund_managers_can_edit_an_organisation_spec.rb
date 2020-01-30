RSpec.feature "Fund managers can edit organisations" do
  let!(:beis_organisation) { create(:organisation) }
  let!(:another_organisation) { create(:organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit edit_organisation_path(beis_organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the fund manager is allowed to edit an organisation" do
    scenario "successfully editing an organisation" do
      authenticate!(user: create(:fund_manager, organisation: beis_organisation))

      successfully_edit_an_organisation
    end

    scenario "presence validation works as expected" do
      authenticate!(user: create(:fund_manager, organisation: beis_organisation))

      visit organisation_path(beis_organisation)
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_link another_organisation.name
      click_link I18n.t("page_content.organisation.button.edit")

      expect(page).to have_content(I18n.t("page_title.organisation.edit"))
      fill_in "organisation[name]", with: "My New Organisation"

      click_button I18n.t("generic.button.submit")
      expect(page).to_not have_content I18n.t("form.organisation.update.success")
      expect(page).to have_content "can't be blank"
    end
  end

  context "when the user is a delivery partner" do
    scenario "cannot edit an organisation" do
      authenticate!(user: create(:delivery_partner, organisation: another_organisation))

      visit organisation_path(another_organisation)

      expect(page).to_not have_content(I18n.t("page_content.organisation.button.edit"))
    end

    context "and does not belong to the organisation" do
      scenario "cannot visit that organisations page" do
        first_organisation = create(:organisation)
        second_organisation = create(:organisation)
        authenticate!(user: create(:delivery_partner, organisation: first_organisation))

        visit organisation_path(second_organisation)

        expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
      end

      scenario "shows the 'unauthorised' error message to the user" do
        first_organisation = create(:organisation)
        second_organisation = create(:organisation)

        authenticate!(user: create(:delivery_partner, organisation: first_organisation))

        visit edit_organisation_path(second_organisation)

        expect(page).to have_content(I18n.t("pundit.default"))
        expect(page).to have_http_status(:unauthorized)
      end
    end
  end

  def successfully_edit_an_organisation
    visit organisation_path(beis_organisation)

    click_link I18n.t("page_content.dashboard.button.manage_organisations")

    click_link another_organisation.name
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
