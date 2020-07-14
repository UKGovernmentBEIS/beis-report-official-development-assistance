RSpec.feature "Users can create a project" do
  let(:beis) { create(:delivery_partner_organisation) }

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "a new project can be added to a programme" do
      programme = create(:programme_activity, extending_organisation: user.organisation)

      visit activities_path
      click_on(I18n.t("page_content.organisation.button.create_activity"))

      fill_in_activity_form(level: "project", parent: programme)

      expect(page).to have_content I18n.t("action.project.create.success")
      expect(programme.child_activities.count).to eq 1

      project = programme.child_activities.last

      expect(project.organisation).to eq user.organisation
    end

    scenario "project creation is tracked with public_activity" do
      programme = create(:programme_activity, extending_organisation: user.organisation)

      PublicActivity.with_tracking do
        visit activities_path
        click_on(I18n.t("page_content.organisation.button.create_activity"))

        fill_in_activity_form(level: "project", identifier: "my-unique-identifier", parent: programme)

        project = Activity.find_by(identifier: "my-unique-identifier")
        auditable_events = PublicActivity::Activity.where(trackable_id: project.id)
        expect(auditable_events.map { |event| event.key }).to include("activity.create", "activity.create.identifier", "activity.create.purpose", "activity.create.sector", "activity.create.geography", "activity.create.region", "activity.create.flow", "activity.create.aid_type")
        expect(auditable_events.map { |event| event.owner_id }.uniq).to eq [user.id]
        expect(auditable_events.map { |event| event.trackable_id }.uniq).to eq [project.id]
      end
    end
  end
end
