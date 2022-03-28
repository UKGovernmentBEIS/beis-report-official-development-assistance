RSpec.feature "Users can view an activity's details" do
  context "when the user is signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: user)
    end

    scenario "the activity details can be viewed" do
      activity = create(:project_activity, organisation: user.organisation)

      visit organisation_activity_details_path(activity.organisation, activity)

      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Details"
      end
      expect(page).to have_content activity.title
      expect(page).to have_link t("page_content.activity.implementing_organisation.button.new")
    end

    scenario "activities have human readable date format" do
      travel_to Time.zone.local(2020, 1, 29) do
        activity = create(:project_activity,
          planned_start_date: Date.new(2020, 2, 3),
          planned_end_date: Date.new(2024, 6, 22),
          actual_start_date: Date.new(2020, 1, 2),
          actual_end_date: Date.new(2020, 1, 29),
          organisation: user.organisation)

        visit organisation_activity_path(user.organisation, activity)
        click_on t("tabs.activity.details")

        within(".planned_start_date") do
          expect(page).to have_content("3 Feb 2020")
        end

        within(".planned_end_date") do
          expect(page).to have_content("22 Jun 2024")
        end

        within(".actual_start_date") do
          expect(page).to have_content("2 Jan 2020")
        end

        within(".actual_end_date") do
          expect(page).to have_content("29 Jan 2020")
        end
      end
    end
  end
end
