RSpec.feature "Users can create a third-party project" do
  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "when viewing a project" do
      scenario "a new third party project cannot be added to the programme when a report does not exist" do
        programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
        project = create(:project_activity, :gcrf_funded, organisation: user.organisation, parent: programme)

        visit activities_path
        click_on project.title
        click_on t("tabs.activity.children")

        expect(page).to_not have_button(t("action.activity.add_child"))
      end

      scenario "a new third party project can be added to the project" do
        programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
        project = create(:project_activity, :gcrf_funded, organisation: user.organisation, extending_organisation: user.organisation, parent: programme)
        _report = create(:report, state: :active, organisation: user.organisation, fund: project.associated_fund)

        visit activities_path

        click_on(project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        fill_in_activity_form(level: "third_party_project", parent: project)

        expect(page).to have_content t("action.third_party_project.create.success")
        expect(project.child_activities.count).to eq 1

        third_party_project = project.child_activities.last

        expect(third_party_project.organisation).to eq user.organisation
      end

      context "without an editable report" do
        scenario "a new third party project cannot be added" do
          programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
          project = create(:project_activity, :gcrf_funded, organisation: user.organisation, extending_organisation: user.organisation, parent: programme)

          visit activities_path

          click_on(project.title)
          click_on t("tabs.activity.children")

          expect(page).to have_no_button t("action.activity.add_child")
        end
      end

      scenario "the activity saves its identifier as read-only `transparency_identifier`" do
        programme = create(:programme_activity, :gcrf_funded, extending_organisation: user.organisation)
        project = create(:project_activity, :gcrf_funded, organisation: user.organisation, extending_organisation: user.organisation, parent: programme)
        _report = create(:report, state: :active, organisation: user.organisation, fund: project.associated_fund)

        visit activities_path

        click_on(project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        fill_in_activity_form(level: "third_party_project", parent: project)

        activity = Activity.order("created_at ASC").last
        expect(activity.transparency_identifier).to eql("GB-GOV-13-#{activity.roda_identifier}")
      end

      scenario "a new third party project requires specific fields when the project is Newton-funded" do
        newton_fund = create(:fund_activity, :newton)
        newton_programme = create(:programme_activity, parent: newton_fund, extending_organisation: user.organisation)
        newton_project = create(:project_activity, parent: newton_programme, organisation: user.organisation, extending_organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: newton_fund)

        visit activities_path

        click_on(newton_project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        fill_in_activity_form(level: "third_party_project", parent: newton_project)
      end
    end
  end
end
