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
      activity = create(:project_activity)
      visit activities_path

      expect(page).to have_content activity.parent.title
      expect(page).to have_content activity.parent.identifier

      select activity.organisation.name, from: "organisation_id"
      click_on I18n.t("filters.activity.submit")

      expect(page).to have_content activity.title
      expect(page).to have_content activity.identifier
    end
  end

  context "when the user is signed in as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "they see the organisation filter on the activities index" do
      visit root_path
      within "#navigation" do
        click_on "Activities"
      end

      expect(page).not_to have_content I18n.t("filters.activity.title")
      expect(page).not_to have_select "organisation_id"
    end
  end
end
