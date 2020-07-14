RSpec.feature "Users can create a project" do
  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    context "when viewing a project" do
      scenario "a new third party project can be added to the project" do
        project = create(:project_activity, organisation: user.organisation)

        visit activities_path

        click_on(project.title)
        click_on I18n.t("tabs.activity.details")

        click_on(I18n.t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(level: "third_party_project", parent: project)

        expect(page).to have_content I18n.t("action.third_party_project.create.success")
        expect(project.child_activities.count).to eq 1

        third_party_project = project.child_activities.last

        expect(third_party_project.organisation).to eq user.organisation
      end

      scenario "third party project creation is tracked with public_activity" do
        project = create(:project_activity, organisation: user.organisation)

        PublicActivity.with_tracking do
          visit activities_path

          click_on(project.title)
          click_on I18n.t("tabs.activity.details")

          click_on(I18n.t("page_content.organisation.button.create_activity"))

          fill_in_activity_form(level: "third_party_project", identifier: "my-unique-identifier", parent: project)

          third_party_project = Activity.find_by(identifier: "my-unique-identifier")
          auditable_events = PublicActivity::Activity.where(trackable_id: third_party_project.id)
          expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.flow", "activity.create.aid_type")
          expect(auditable_events.map { |event| event.owner_id }.uniq).to eq [user.id]
          expect(auditable_events.map { |event| event.trackable_id }.uniq).to eq [third_party_project.id]
        end
      end
    end
  end
end
