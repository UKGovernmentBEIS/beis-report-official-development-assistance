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
    context "and the activity is a fund" do
      scenario "the child programme activities can be viewed" do
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund)

        visit organisation_activity_children_path(fund.organisation, fund)

        expect(page).to have_content programme.title
        expect(page).to have_content programme.identifier
      end

      scenario "they see 'Incomplete' next to incomplete programmes" do
        fund = create(:fund_activity)
        incomplete_programme = create(:programme_activity, :at_purpose_step, parent: fund)

        visit organisation_activity_children_path(fund.organisation, fund)

        within("##{incomplete_programme.id}") do
          expect(page).to have_link incomplete_programme.title
          expect(page).to have_content I18n.t("summary.label.activity.form_state.incomplete")
        end
      end

      scenario "they do not see a Publish to Iati column & status against programmes" do
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund)

        visit organisation_activity_children_path(fund.organisation, fund)

        within(".programmes") do
          expect(page).to_not have_content I18n.t("summary.label.activity.publish_to_iati.label")
        end

        within("##{programme.id}") do
          expect(page).to_not have_content I18n.t("summary.label.activity.publish_to_iati.yes")
        end
      end
    end

    scenario "the activity financials can be viewed" do
      activity = create(:activity, organisation: user.organisation)
      transaction = create(:transaction, parent_activity: activity)
      budget = create(:budget, parent_activity: activity)

      visit organisation_activity_financials_path(activity.organisation, activity)
      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Financials"
      end
      expect(page).to have_content transaction.value
      expect(page).to have_content budget.value
    end

    scenario "the activity child activities can be viewed in a tab" do
      activity = create(:activity, organisation: user.organisation)

      visit organisation_activity_children_path(activity.organisation, activity)

      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Child activities"
      end
      expect(page).to have_content activity.title
      expect(page).to have_button I18n.t("page_content.organisation.button.create_activity")
    end

    scenario "the activity details tab can be viewed" do
      activity = create(:activity, organisation: user.organisation)

      visit organisation_activity_details_path(activity.organisation, activity)

      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Details"
      end
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

    scenario "the activity links to the parent activity" do
      activity = create(:programme_activity, organisation: user.organisation)
      parent_activity = activity.parent

      visit organisation_activity_details_path(activity.organisation, activity)

      expect(page).to have_link parent_activity.title, href: organisation_activity_path(parent_activity.organisation, parent_activity)
    end

    scenario "a fund activity has human readable date format" do
      travel_to Time.zone.local(2020, 1, 29) do
        activity = create(:activity, planned_start_date: Date.new(2020, 2, 3),
                                     planned_end_date: Date.new(2024, 6, 22),
                                     actual_start_date: Date.new(2020, 1, 2),
                                     actual_end_date: Date.new(2020, 1, 29))

        visit organisation_activity_path(user.organisation, activity)
        click_on I18n.t("tabs.activity.details")

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

  context "when the user is signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "a programme activity does not link to its parent activity" do
      activity = create(:programme_activity, organisation: user.organisation)
      parent_activity = activity.parent

      visit organisation_activity_details_path(activity.organisation, activity)

      expect(page).not_to have_link parent_activity.title, href: organisation_activity_path(parent_activity.organisation, parent_activity)
      expect(page).to have_content parent_activity.title
    end
  end
end
