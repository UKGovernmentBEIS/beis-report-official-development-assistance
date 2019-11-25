RSpec.feature "Users can create organisations" do
  before do
    authenticate!(user: build_stubbed(:administrator))
  end

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit new_organisation_path
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is not allowed to add a new user" do
    before do
      authenticate!(user: build_stubbed(:user))
    end

    scenario "hides the 'Create organisation' button" do
      visit organisations_path

      expect(page).to have_no_content(I18n.t("page_content.organisations.button.create"))
    end

    scenario "shows the 'unauthorised' error message to the user" do
      visit new_organisation_path

      expect(page).to have_content(I18n.t("pundit.default"))
      expect(page).to have_http_status(:unauthorized)
    end
  end

  scenario "successfully creating an organisation" do
    visit new_organisation_path

    expect(page).to have_content(I18n.t("page_title.organisation.new"))
    fill_in "organisation[name]", with: "My New Organisation"
    select "Government", from: "organisation[organisation_type]"
    select "Czech", from: "organisation[language_code]"
    select "Zloty", from: "organisation[default_currency]"
    click_button I18n.t("form.organisation.submit")
    expect(page).to have_content I18n.t("form.organisation.create.success")
  end

  scenario "presence validation works as expected" do
    mock_successful_authentication(name: "Alex Smith")

    visit new_organisation_path

    expect(page).to have_content(I18n.t("page_title.organisation.new"))
    fill_in "organisation[name]", with: "My New Organisation"

    click_button I18n.t("form.organisation.submit")
    expect(page).to_not have_content I18n.t("form.organisation.create.success")
    expect(page).to have_content "can't be blank"
  end
end
