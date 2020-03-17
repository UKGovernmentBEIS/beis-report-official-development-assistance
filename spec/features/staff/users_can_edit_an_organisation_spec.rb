RSpec.feature "Users can edit organisations" do
  let!(:beis_organisation) { create(:beis_organisation) }
  let!(:another_organisation) { create(:organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      visit edit_organisation_path(beis_organisation)
      expect(current_path).to eq(root_path)
    end
  end

  scenario "successfully editing an organisation" do
    authenticate!(user: create(:administrator, organisation: beis_organisation))

    successfully_edit_an_organisation
  end

  scenario "presence validation works as expected" do
    authenticate!(user: create(:administrator, organisation: beis_organisation))

    visit organisation_path(beis_organisation)
    click_link I18n.t("page_content.dashboard.button.manage_organisations")
    click_link another_organisation.name
    click_link I18n.t("page_content.organisation.button.edit")

    expect(page).to have_content(I18n.t("page_title.organisation.edit"))
    fill_in "organisation[name]", with: ""

    click_button I18n.t("generic.button.submit")
    expect(page).to_not have_content I18n.t("form.organisation.update.success")
    expect(page).to have_content "can't be blank"
  end

  def successfully_edit_an_organisation
    visit organisation_path(beis_organisation)

    click_link I18n.t("page_content.dashboard.button.manage_organisations")

    click_link another_organisation.name
    click_link I18n.t("page_content.organisation.button.edit")

    expect(page).to have_content(I18n.t("page_title.organisation.edit"))
    fill_in "organisation[name]", with: "My New Organisation"
    fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
    select "Government", from: "organisation[organisation_type]"
    select "Czech", from: "organisation[language_code]"
    select "Zloty", from: "organisation[default_currency]"
    click_button I18n.t("generic.button.submit")
    expect(page).to have_content I18n.t("form.organisation.update.success")
  end
end
