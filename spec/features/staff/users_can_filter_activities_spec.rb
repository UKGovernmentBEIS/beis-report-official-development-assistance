RSpec.feature "Users can filter activities" do
  context "when the user is signed in as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "they see the organisation filter on the activities index" do
      visit root_path
      within "#navigation" do
        click_on "Activities"
      end

      expect(page).to have_content t("filters.activity.title")
      expect(page).to have_select "organisation_id"
    end

    scenario "the BEIS organisation is the default selection on the activities index" do
      visit activities_path

      expect(page).to have_select "organisation_id", selected: "Department for Business, Energy and Industrial Strategy"
    end

    scenario "the organisations are in alphabetical order" do
      create(:delivery_partner_organisation, name: "Zorg")
      create(:delivery_partner_organisation, name: "Aardvark")

      visit activities_path

      expect(page.all("#organisation_id option").first).to have_text("Aardvark")
      expect(page.all("#organisation_id option").last).to have_text("Zorg")
    end

    scenario "they can filter the activities to an organisation" do
      delivery_partner_organisation = create(:delivery_partner_organisation)
      programme = create(:programme_activity, extending_organisation: delivery_partner_organisation)
      project = create(:project_activity, organisation: delivery_partner_organisation, parent: programme)

      visit activities_path

      expect(page).to have_content programme.title
      expect(page).to have_content programme.roda_identifier

      select delivery_partner_organisation.name, from: "organisation_id"
      click_on t("filters.activity.submit")

      expect(page).to have_content project.title
      expect(page).to have_content project.roda_identifier
    end

    scenario "they will see Current activities if they filter while on the 'Current' tab" do
      delivery_partner_organisation = create(:delivery_partner_organisation)
      current_programme = create(:programme_activity, extending_organisation: delivery_partner_organisation)
      current_project = create(:project_activity, organisation: delivery_partner_organisation, parent: current_programme)
      historic_programme = create(:programme_activity, extending_organisation: delivery_partner_organisation, programme_status: "cancelled")
      historic_project = create(:project_activity, organisation: delivery_partner_organisation, programme_status: "cancelled", parent: historic_programme)

      visit activities_path

      select delivery_partner_organisation.name, from: "organisation_id"
      click_on t("filters.activity.submit")

      expect(page).to have_content current_project.title
      expect(page).to have_content current_project.roda_identifier
      expect(page).to_not have_content historic_project.title
      expect(page).to_not have_content historic_project.roda_identifier
    end

    scenario "they will see Historic activities if they filter while on the 'Historic' tab" do
      delivery_partner_organisation = create(:delivery_partner_organisation)
      current_programme = create(:programme_activity, extending_organisation: delivery_partner_organisation)
      current_project = create(:project_activity, organisation: delivery_partner_organisation, parent: current_programme)
      historic_programme = create(:programme_activity, extending_organisation: delivery_partner_organisation, programme_status: "cancelled")
      historic_project = create(:project_activity, organisation: delivery_partner_organisation, programme_status: "cancelled", parent: historic_programme)

      visit historic_activities_path

      select delivery_partner_organisation.name, from: "organisation_id"
      click_on t("filters.activity.submit")

      expect(page).to have_content historic_project.title
      expect(page).to have_content historic_project.roda_identifier
      expect(page).to_not have_content current_project.title
      expect(page).to_not have_content current_project.roda_identifier
    end
  end

  context "when the user is signed in as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "they do not see the organisation filter on the activities index" do
      visit root_path
      within "#navigation" do
        click_on "Activities"
      end

      expect(page).not_to have_content t("filters.activity.title")
      expect(page).not_to have_select "organisation_id"
    end
  end
end
