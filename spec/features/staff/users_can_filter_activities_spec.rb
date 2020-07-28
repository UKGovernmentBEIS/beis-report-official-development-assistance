RSpec.feature "Users can filter activities" do
  context "when the user is signed in as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "they see the organisation filter on the activities index" do
      visit root_path
      within "#navigation" do
        click_on "Activities"
      end

      expect(page).to have_content I18n.t("filters.activity.title")
      expect(page).to have_select "organisation_id"
    end

    scenario "they can filter the activities to an organisation" do
      delivery_partner_organisation = create(:delivery_partner_organisation)
      programme = create(:programme_activity, organisation: user.organisation)
      project = create(:project_activity, organisation: delivery_partner_organisation, parent: programme)

      visit activities_path

      expect(page).to have_content programme.title
      expect(page).to have_content programme.identifier

      select delivery_partner_organisation.name, from: "organisation_id"
      click_on I18n.t("filters.activity.submit")

      expect(page).to have_content project.title
      expect(page).to have_content project.identifier
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

      expect(page).not_to have_content I18n.t("filters.activity.title")
      expect(page).not_to have_select "organisation_id"
    end
  end
end
