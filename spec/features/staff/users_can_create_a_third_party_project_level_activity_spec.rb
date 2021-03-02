RSpec.feature "Users can create a third-party project" do
  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "when viewing a project" do
      scenario "a new third party project can be added to the project" do
        project = create(:project_activity, :gcrf_funded, organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: project.associated_fund)

        visit activities_path

        click_on(project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        fill_in_activity_form(level: "third_party_project", parent: project, skip_level_and_parent_steps: true)

        expect(page).to have_content t("action.third_party_project.create.success")
        expect(project.child_activities.count).to eq 1

        third_party_project = project.child_activities.last

        expect(third_party_project.organisation).to eq user.organisation
      end

      scenario "the activity saves its identifier as read-only `transparency_identifier`" do
        project = create(:project_activity, :gcrf_funded, organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: project.associated_fund)
        identifier = "3rd-party-proj"

        visit activities_path

        click_on(project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        fill_in_activity_form(level: "third_party_project", roda_identifier_fragment: identifier, parent: project, skip_level_and_parent_steps: true)

        activity = Activity.find_by(roda_identifier_fragment: identifier)
        expect(activity.transparency_identifier).to eql("GB-GOV-13-#{project.parent.parent.roda_identifier_fragment}-#{project.parent.roda_identifier_fragment}-#{project.roda_identifier_fragment}#{activity.roda_identifier_fragment}")
      end

      scenario "third party project creation is tracked with public_activity" do
        project = create(:project_activity, :gcrf_funded, organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: project.associated_fund)

        PublicActivity.with_tracking do
          visit activities_path

          click_on(project.title)
          click_on t("tabs.activity.children")

          click_on(t("action.activity.add_child"))

          fill_in_activity_form(level: "third_party_project", delivery_partner_identifier: "my-unique-identifier", parent: project, skip_level_and_parent_steps: true)

          third_party_project = Activity.find_by(delivery_partner_identifier: "my-unique-identifier")
          auditable_events = PublicActivity::Activity.where(trackable_id: third_party_project.id)
          expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.aid_type")
          expect(auditable_events.map { |event| event.owner_id }.uniq).to eq [user.id]
          expect(auditable_events.map { |event| event.trackable_id }.uniq).to eq [third_party_project.id]
        end
      end

      scenario "a new third party project requires specific fields when the project is Newton-funded" do
        newton_fund = create(:fund_activity, :newton)
        newton_programme = create(:programme_activity, parent: newton_fund, extending_organisation: user.organisation)
        newton_project = create(:project_activity, parent: newton_programme, organisation: user.organisation)
        _report = create(:report, state: :active, organisation: user.organisation, fund: newton_fund)

        visit activities_path

        click_on(newton_project.title)
        click_on t("tabs.activity.children")

        click_on(t("action.activity.add_child"))

        fill_in_activity_form(level: "third_party_project", parent: newton_project, skip_level_and_parent_steps: true)
      end
    end
  end
end
