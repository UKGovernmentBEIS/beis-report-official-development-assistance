RSpec.feature "BEIS users can create organisations" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit new_organisation_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is authenticated" do
    let(:user) { create(:beis_user) }
    before do
      authenticate!(user: user)
    end

    scenario "successfully creating an organisation" do
      visit organisation_path(user.organisation)
      click_link I18n.t("page_title.organisation.index")
      click_link I18n.t("page_content.organisations.button.create")

      expect(page).to have_content(I18n.t("page_title.organisation.new"))
      fill_in "organisation[name]", with: "My New Organisation"
      fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
      select "Government", from: "organisation[organisation_type]"
      select "Czech", from: "organisation[language_code]"
      select "Zloty", from: "organisation[default_currency]"
      click_button I18n.t("generic.button.submit")
    end

    scenario "successfully creating an organisation" do
      visit organisation_path(user.organisation)
      click_link I18n.t("page_title.organisation.index")
      click_link I18n.t("page_content.organisations.button.create")

      expect(page).to have_content(I18n.t("page_title.organisation.new"))
      fill_in "organisation[name]", with: "My New Organisation"
      fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
      select "Government", from: "organisation[organisation_type]"
      select "Czech", from: "organisation[language_code]"
      select "Zloty", from: "organisation[default_currency]"
      click_button I18n.t("generic.button.submit")

      expect(page).to have_content I18n.t("form.organisation.create.success")
    end

    scenario "presence validation works as expected" do
      visit organisation_path(user.organisation)
      click_link I18n.t("page_title.organisation.index")
      click_link I18n.t("page_content.organisations.button.create")

      expect(page).to have_content(I18n.t("page_title.organisation.new"))
      fill_in "organisation[name]", with: "My New Organisation"

      click_button I18n.t("generic.button.submit")
      expect(page).to_not have_content I18n.t("form.organisation.create.success")
      expect(page).to have_content "can't be blank"
    end

    context "when the user does not belongs to BEIS" do
      let(:user) { create(:delivery_partner_user) }

      it "does not show them the manage user button" do
        visit organisation_path(user.organisation)
        expect(page).not_to have_content(I18n.t("page_content.dashboard.button.manage_organisations"))
      end
    end
  end
end
