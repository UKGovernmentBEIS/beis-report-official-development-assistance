RSpec.feature "Users can edit organisations" do
  let!(:beis_organisation) { create(:beis_organisation) }
  let!(:another_organisation) { create(:delivery_partner_organisation) }

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

    within ".govuk-header__navigation" do
      click_link t("page_title.organisation.index")
    end

    within("##{another_organisation.id}") do
      click_link t("default.link.edit")
    end

    expect(page).to have_content(t("page_title.organisation.edit"))
    fill_in "organisation[name]", with: ""

    click_button t("default.button.submit")
    expect(page).to_not have_content t("action.organisation.update.success")
    expect(page).to have_content t("activerecord.errors.models.organisation.attributes.name.blank")
  end

  context "when the organisation is a matched effort provider organisation" do
    let!(:another_organisation) { create(:matched_effort_provider) }

    scenario "it can be set to inactive" do
      authenticate!(user: create(:administrator, organisation: beis_organisation))

      visit organisation_path(beis_organisation)

      within ".govuk-header__navigation" do
        click_link t("page_title.organisation.index")
      end

      click_link t("tabs.organisations.matched_effort_providers")

      within("##{another_organisation.id}") do
        click_link t("default.link.edit")
      end

      choose t("form.label.organisation.active.false"), name: "organisation[active]"
      expect {
        click_button t("default.button.submit")
      }.to change {
        another_organisation.reload.active
      }.from(true).to(false)

      expect(page).to have_content t("action.organisation.update.success")
    end
  end

  context "when the organisation is an external income provider organisation" do
    let!(:another_organisation) { create(:external_income_provider) }

    scenario "it can be set to inactive" do
      authenticate!(user: create(:administrator, organisation: beis_organisation))

      visit organisation_path(beis_organisation)

      within ".govuk-header__navigation" do
        click_link t("page_title.organisation.index")
      end

      click_link t("tabs.organisations.external_income_providers")

      within("##{another_organisation.id}") do
        click_link t("default.link.edit")
      end

      choose t("form.label.organisation.active.false"), name: "organisation[active]"
      expect {
        click_button t("default.button.submit")
      }.to change {
        another_organisation.reload.active
      }.from(true).to(false)

      expect(page).to have_content t("action.organisation.update.success")
    end
  end

  def successfully_edit_an_organisation(organisation_name: "My New Organisation")
    visit organisation_path(beis_organisation)

    within ".govuk-header__navigation" do
      click_link t("page_title.organisation.index")
    end

    within("##{another_organisation.id}") do
      click_link t("default.link.edit")
    end

    expect(page).to have_content(t("page_title.organisation.edit"))
    fill_in "organisation[name]", with: organisation_name
    fill_in "organisation[iati_reference]", with: "CZH-GOV-1234"
    select "Government", from: "organisation[organisation_type]"
    select "Czech", from: "organisation[language_code]"
    select "Zloty", from: "organisation[default_currency]"
    click_button t("default.button.submit")
    expect(page).to have_content t("action.organisation.update.success")
  end
end
