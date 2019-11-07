RSpec.feature "Users can create organisations" do
  scenario "successfully creating an organisation" do
    mock_successful_authentication(name: "Alex Smith")

    visit new_organisation_path

    expect(page).to have_content(I18n.t("page_title.create_organisation"))
    fill_in "organisation[name]", with: "My New Organisation"
    select "Government", from: "organisation[organisation_type]"
    select "Czech", from: "organisation[language_code]"
    select "Zloty", from: "organisation[default_currency]"
    click_button I18n.t("create_organisation.submit")
    expect(page).to have_content I18n.t("create_organisation.create.success")
  end

  scenario "presence validation works as expected" do
    mock_successful_authentication(name: "Alex Smith")

    visit new_organisation_path

    expect(page).to have_content(I18n.t("page_title.create_organisation"))
    fill_in "organisation[name]", with: "My New Organisation"

    click_button I18n.t("create_organisation.submit")
    expect(page).to_not have_content I18n.t("create_organisation.create.success")
    expect(page).to have_content "can't be blank"
  end
end
