RSpec.feature "Users can view organisations" do
  context "a user who successfully logged in" do
    before do
      mock_successful_authentication(name: "Alex Smith")
      log_in
    end

    scenario "organisation index page" do
      organisation = FactoryBot.create(:organisation)

      visit organisations_path

      expect(page).to have_content(I18n.t("page_title.organisations"))
      expect(page).to have_content organisation.name
    end

    scenario "organisation show page" do
      organisation = FactoryBot.create(:organisation)

      visit organisations_path
      click_link organisation.name

      expect(page).to have_content(organisation.name)
      expect(page).to have_content(organisation.organisation_type)
      expect(page).to have_content(organisation.language_code)
      expect(page).to have_content(organisation.default_currency)
    end
  end

  context "a visitor who is not logged in" do
    scenario "trying to access organisation index results in redirection" do
      organisation = FactoryBot.create(:organisation)

      visit organisations_path

      expect(page).to have_content(I18n.t("generic.link.start_now"))
      expect(page).to_not have_content organisation.name
    end

    scenario "trying to access an organisation results in redirection" do
      organisation = FactoryBot.create(:organisation)

      visit organisation_path(organisation.id)

      expect(page).to have_content(I18n.t("generic.link.start_now"))
      expect(page).to_not have_content organisation.name
    end
  end
end
