RSpec.feature "Users can view organisations" do
  scenario "organisation index page" do
    mock_successful_authentication(name: "Alex Smith")
    organisation = FactoryBot.create(:organisation)

    visit organisations_path

    expect(page).to have_content(I18n.t("page_title.organisations"))
    expect(page).to have_content organisation.name
  end

  scenario "organisation show page" do
    mock_successful_authentication(name: "Alex Smith")
    organisation = FactoryBot.create(:organisation)

    visit organisations_path
    click_link organisation.name

    expect(page).to have_content(organisation.name)
    expect(page).to have_content(organisation.organisation_type)
    expect(page).to have_content(organisation.language_code)
    expect(page).to have_content(organisation.default_currency)
  end
end
