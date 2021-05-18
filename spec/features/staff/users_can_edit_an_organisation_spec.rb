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

  scenario "organisation update is tracked by public_activity" do
    user = create(:administrator, organisation: beis_organisation)
    authenticate!(user: user)

    PublicActivity.with_tracking do
      successfully_edit_an_organisation(organisation_name: "My Edited Organisation")

      organisation = Organisation.find_by(name: "My Edited Organisation")
      auditable_event = PublicActivity::Activity.find_by(trackable_id: organisation.id)
      expect(auditable_event.key).to eq "organisation.update"
      expect(auditable_event.owner_id).to eq user.id
      expect(auditable_event.trackable_id).to eq organisation.id
    end
  end

  scenario "presence validation works as expected" do
    authenticate!(user: create(:administrator, organisation: beis_organisation))

    visit organisation_path(beis_organisation)
    click_link t("page_title.organisation.index")
    within("##{another_organisation.id}") do
      click_link t("default.link.edit")
    end

    expect(page).to have_content(t("page_title.organisation.edit"))
    fill_in "organisation[name]", with: ""

    click_button t("default.button.submit")
    expect(page).to_not have_content t("action.organisation.update.success")
    expect(page).to have_content t("activerecord.errors.models.organisation.attributes.name.blank")
  end

  def successfully_edit_an_organisation(organisation_name: "My New Organisation")
    visit organisation_path(beis_organisation)

    click_link t("page_title.organisation.index")

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
