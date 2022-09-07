RSpec.feature "Users can view an activity's children" do
  context "when the user is signed in as a partner organisation user" do
    let(:user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: user)
    end

    scenario "they do not see a Publish to Iati column & status against child activities" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, organisation: user.organisation, parent: programme)

      visit organisation_activity_path(user.organisation.id, project)

      click_on t("tabs.activity.details")
      within(".activity-details") do
        click_on programme.title
      end
      click_on t("tabs.activity.children")

      expect(page).to_not have_content t("summary.label.activity.publish_to_iati.label")

      within("##{project.id}") do
        expect(page).to_not have_content t("summary.label.activity.publish_to_iati.true")
      end
    end

    scenario "a child activity can be viewed" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      activity = create(:project_activity, parent: programme, organisation: user.organisation, sdgs_apply: true, sdg_1: 5)

      visit organisation_activity_details_path(activity.organisation, activity)

      within(".activity-details") do
        click_on(programme.title)
      end
      click_on t("tabs.activity.children")
      click_on activity.title
      click_on t("tabs.activity.details")

      activity_presenter = ActivityPresenter.new(activity)

      expect(page).to have_content activity_presenter.roda_identifier
      expect(page).to have_content activity_presenter.sector
      expect(page).to have_content activity_presenter.title
      expect(page).to have_content activity_presenter.description
      expect(page).to have_content activity_presenter.planned_start_date
      expect(page).to have_content activity_presenter.planned_end_date
      expect(page).to have_content activity_presenter.recipient_region

      within ".sustainable_development_goals" do
        expect(page).to have_content "Gender Equality"
      end
    end
  end
end
