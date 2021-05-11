RSpec.describe "Users can view planned disbursements" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "they can view planned disbursements on projects" do
      project = create(:project_activity, organisation: user.organisation)
      planned_disbursement = create(:planned_disbursement, parent_activity: project)

      visit organisation_activity_path(user.organisation, project)

      expect(page).to have_content t("page_content.activity.planned_disbursements")
      expect(page).to have_selector "##{planned_disbursement.id}"
    end

    scenario "they can view planned disbursements on third-party projects" do
      third_party_project = create(:third_party_project_activity, organisation: user.organisation)
      planned_disbursement = create(:planned_disbursement, parent_activity: third_party_project)

      visit organisation_activity_path(user.organisation, third_party_project)

      expect(page).to have_content t("page_content.activity.planned_disbursements")
      expect(page).to have_selector "##{planned_disbursement.id}"
    end
  end

  context "when signed in as a beis user" do
    let(:beis_user) { create(:beis_user) }
    before { authenticate!(user: beis_user) }

    scenario "they can view planned disbursements on projects" do
      project = create(:project_activity)
      planned_disbursement = create(:planned_disbursement, parent_activity: project)

      visit organisation_activity_path(beis_user.organisation, project)

      expect(page).to have_content t("page_content.activity.planned_disbursements")
      expect(page).to have_selector "##{planned_disbursement.id}"
    end

    scenario "they can view planned disbursements on third-party projects" do
      third_party_project = create(:third_party_project_activity)
      planned_disbursement = create(:planned_disbursement, parent_activity: third_party_project)

      visit organisation_activity_path(beis_user.organisation, third_party_project)

      expect(page).to have_content t("page_content.activity.planned_disbursements")
      expect(page).to have_selector "##{planned_disbursement.id}"
    end
  end
end
