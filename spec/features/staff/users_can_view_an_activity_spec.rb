RSpec.feature "Users can view an activity" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      activity = create(:activity)
      visit organisation_activity_path(activity.organisation, activity)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "the activity financials can be viewed" do
      activity = create(:activity, organisation: user.organisation)

      visit organisation_activity_financials_path(activity.organisation, activity)
      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Financials"
      end
    end

    scenario "the activity details can be viewed" do
      activity = create(:activity, organisation: user.organisation)

      visit organisation_activity_details_path(activity.organisation, activity)

      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Details"
      end
    end

    scenario "an activity can be viewed" do
      activity = create(:activity, organisation: user.organisation)

      visit organisation_path(user.organisation)

      click_on(activity.title)
      activity_presenter = ActivityPresenter.new(activity)

      expect(page).to have_content activity_presenter.identifier
      expect(page).to have_content activity_presenter.sector
      expect(page).to have_content activity_presenter.title
      expect(page).to have_content activity_presenter.description
      expect(page).to have_content activity_presenter.planned_start_date
      expect(page).to have_content activity_presenter.planned_end_date
      expect(page).to have_content activity_presenter.recipient_region
      expect(page).to have_content activity_presenter.flow
    end

    scenario "a fund activity has human readable date format" do
      travel_to Time.zone.local(2020, 1, 29) do
        activity = create(:activity, planned_start_date: Date.new(2020, 2, 3),
                                     planned_end_date: Date.new(2024, 6, 22),
                                     actual_start_date: Date.new(2020, 1, 2),
                                     actual_end_date: Date.new(2020, 1, 29))

        visit organisation_activity_path(user.organisation, activity)

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

    scenario "can go back to the previous page" do
      activity = create(:activity, organisation: user.organisation)

      visit organisation_activity_path(user.organisation, activity)

      click_on I18n.t("default.link.back")

      expect(page).to have_current_path(
        organisation_path(user.organisation)
      )
    end
  end
end
