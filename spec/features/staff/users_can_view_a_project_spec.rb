RSpec.feature "Users can view a project" do
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
      third_party_project = create(:third_party_project_activity, activity: project)

      visit organisation_activity_details_path(project.organisation, project)

      expect(page).to have_content third_party_project.title
    end

    context "when viewing a programme" do
      scenario "links to the programmes projects" do
        fund = create(:fund_activity)
        programme = create(:programme_activity)
        fund.child_activities << programme
        project = create(:project_activity, organisation: user.organisation)
        programme.child_activities << project

        visit organisation_activity_details_path(programme.organisation, programme)

        expect(page).to have_content programme.title

        click_on project.title

        expect(page).to have_content project.title
      end
    end

    scenario "cannot download a project as XML" do
      project = create(:project_activity)

      visit organisation_activity_path(project.organisation, project)

      expect(page).to_not have_content I18n.t("default.button.download_as_xml")
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "can view a project but not create one" do
      project = create(:project_activity)

      visit organisation_activity_path(project.organisation, project)

      expect(page).to have_content project.title
      expect(page).to_not have_content I18n.t("page_content.organisation.button.create_project")
    end

    scenario "can download a project as XML" do
      fund = create(:fund_activity)
      programme = create(:programme_activity)
      fund.child_activities << programme
      project = create(:project_activity, organisation: user.organisation)
      programme.child_activities << project
      project_presenter = ActivityXmlPresenter.new(project)

      visit organisation_activity_path(project.organisation, project)

      expect(page).to have_content I18n.t("default.button.download_as_xml")

      click_on I18n.t("default.button.download_as_xml")

      expect(page.response_headers["Content-Type"]).to include("application/xml")

      header = page.response_headers["Content-Disposition"]
      expect(header).to match(/^attachment/)
      expect(header).to match(/filename=\"#{project_presenter.iati_identifier}.xml\"$/)
    end
  end
end
