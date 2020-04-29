RSpec.feature "Users can view a third-party project" do
  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "can view a third-party project" do
      project = create(:project_activity, organisation: user.organisation)
      third_party_project = create(:third_party_project_activity, activity: project)

      visit organisation_activity_path(third_party_project.organisation, third_party_project)

      expect(page).to have_content third_party_project.title
    end

    scenario "when viewing the status the hint text has the correct level" do
      third_party_project = create(:third_party_project_activity)
      visit activity_step_path(third_party_project, :status)

      expect(page).to have_content I18n.t("helpers.hint.activity.status", level: third_party_project.level)
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "can view a third-party project but not create one" do
      third_party_project = create(:third_party_project_activity)

      visit organisation_activity_path(third_party_project.organisation, third_party_project)

      expect(page).to have_content third_party_project.title
      expect(page).to_not have_content I18n.t("page_content.organisation.button.create_third_party_project")
    end
  end
end
