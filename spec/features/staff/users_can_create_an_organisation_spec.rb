RSpec.feature "Users can create organisations" do
  let(:user) { create(:administrator) }

  before do
    authenticate!(user: user)
  end

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit new_organisation_path
      expect(current_path).to eq(root_path)
    end
  end

  scenario "successfully creating an organisation" do
    visit organisation_path(user.organisation)
    click_link I18n.t("page_content.dashboard.button.manage_organisations")
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
    click_link I18n.t("page_content.dashboard.button.manage_organisations")
    click_link I18n.t("page_content.organisations.button.create")

    expect(page).to have_content(I18n.t("page_title.organisation.new"))
    fill_in "organisation[name]", with: "My New Organisation"

    click_button I18n.t("generic.button.submit")
    expect(page).to_not have_content I18n.t("form.organisation.create.success")
    expect(page).to have_content "can't be blank"
  end
end
