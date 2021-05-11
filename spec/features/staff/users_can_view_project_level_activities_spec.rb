RSpec.feature "Users can view project level activities" do
  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "can view a project" do
      fund = create(:fund_activity)
      programme = create(:programme_activity)
      fund.child_activities << programme
      project = create(:project_activity, organisation: user.organisation)
      programme.child_activities << project

      visit organisation_activity_path(project.organisation, project)

      expect(page).to have_content project.title
    end

    scenario "can see a list of third-party projects on the project view" do
      project = create(:project_activity, organisation: user.organisation)
      third_party_project = create(:third_party_project_activity, parent: project)

      visit organisation_activity_children_path(project.organisation, project)

      expect(page).to have_content third_party_project.title
    end

    context "when viewing a programme" do
      scenario "links to the programmes projects" do
        fund = create(:fund_activity)
        programme = create(:programme_activity, extending_organisation: user.organisation)
        fund.child_activities << programme
        project = create(:project_activity, organisation: user.organisation)
        programme.child_activities << project

        visit organisation_activity_children_path(programme.organisation, programme)

        expect(page).to have_content programme.title

        click_on project.title

        expect(page).to have_content project.title
      end
    end

    scenario "cannot download a project as XML" do
      project = create(:project_activity)

      visit organisation_activity_path(project.organisation, project)

      expect(page).to_not have_content t("default.button.download_as_xml")
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "can view a project but not create one" do
      project = create(:project_activity)

      visit organisation_activity_path(project.organisation, project)

      expect(page).to have_content project.title
      expect(page).to have_no_button t("action.activity.add_child")
    end

    scenario "can download a project as XML" do
      fund = create(:fund_activity)
      programme = create(:programme_activity)
      fund.child_activities << programme
      project = create(:project_activity, transparency_identifier: "GB-GOV-13-PROJECT")
      programme.child_activities << project

      visit organisation_activity_path(project.organisation, project)

      expect(page).to have_content t("default.button.download_as_xml")

      click_on t("default.button.download_as_xml")

      expect(page.response_headers["Content-Type"]).to include("application/xml")

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/^attachment/)
      expect(header).to match(/filename=\"#{project.transparency_identifier}.xml\"$/)
    end
  end
end
