RSpec.feature "Users can view activities" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      activity = create(:activity)
      visit organisation_activity_path(activity.organisation, activity)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is signed in as a BEIS user" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "the activities index shows activities associated to the BEIS organisation" do
      activities = create_list(:programme_activity, 2, organisation: user.organisation)
      another_activity = create(:project_activity)

      visit activities_path(organisation_id: user.organisation)
      expect(page).to have_content I18n.t("page_title.activity.index")

      first_activity = activities.first
      last_activity = activities.last

      expect(page).to have_content first_activity.identifier
      expect(page).to have_content last_activity.identifier
      expect(page).not_to have_content another_activity.identifier
    end

    scenario "they can view another organisations activities" do
      delivery_partner = create(:delivery_partner_organisation)
      activity = create(:project_activity, organisation: delivery_partner)

      visit activities_path(organisation_id: activity.organisation)

      expect(page).to have_content activity.identifier
    end

    context "when an organisation id query parameter is not supplied" do
      scenario "it defaults to showing the current users organisation activities" do
        activity = create(:programme_activity, organisation: user.organisation)

        visit activities_path(organisation_id: "")

        expect(page).to have_content activity.identifier
      end
    end

    context "when the organisation id query parameter is not the BEIS organisation id" do
      scenario "it shows the supplied organisation activities" do
        delivery_partner = create(:delivery_partner_organisation)
        activity = create(:project_activity, organisation: delivery_partner)

        visit activities_path(organisation_id: delivery_partner.id)

        expect(page).to have_content activity.identifier
      end
    end

    context "when the organisation id query parameter is not a know organisation" do
      scenario "it defaults to showing the current users organisation activities" do
        activity = create(:programme_activity, organisation: user.organisation)

        visit activities_path(organisation_id: "this-is-no-a-know-organisation")

        expect(page).to have_content activity.identifier
      end
    end

    context "when viewing a programme level activity" do
      scenario "they see 'Incomplete' next to incomplete projects" do
        incomplete_project = create(:project_activity, :at_geography_step)

        visit activities_path
        within("##{incomplete_project.parent.id}") do
          click_on I18n.t("table.body.activity.view_activity")
        end
        click_on I18n.t("tabs.activity.details")

        within("##{incomplete_project.id}") do
          expect(page).to have_link incomplete_project.title
          expect(page).to have_content I18n.t("summary.label.activity.form_state.incomplete")
        end
      end

      scenario "they see a Publish to Iati column & status against projects" do
        project = create(:project_activity)

        visit activities_path
        within("##{project.parent.id}") do
          click_on I18n.t("table.body.activity.view_activity")
        end
        click_on I18n.t("tabs.activity.details")

        expect(page).to have_content I18n.t("summary.label.activity.publish_to_iati.label")

        within("##{project.id}") do
          expect(page).to have_content "Yes"
        end
      end
    end
  end

  context "when the user is signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "the activity financials can be viewed" do
      activity = create(:project_activity, organisation: user.organisation)
      transaction = create(:transaction, parent_activity: activity)
      budget = create(:budget, parent_activity: activity)

      visit organisation_activity_financials_path(activity.organisation, activity)
      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Financials"
      end
      expect(page).to have_content transaction.value
      expect(page).to have_content budget.value
    end

    scenario "the activity details can be viewed" do
      activity = create(:project_activity, organisation: user.organisation)

      visit organisation_activity_details_path(activity.organisation, activity)

      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Details"
      end
      expect(page).to have_content activity.title
      expect(page).to have_link I18n.t("page_content.activity.implementing_organisation.button.new")
    end

    scenario "all activities can be viewed" do
      activities = create_list(:project_activity, 2, organisation: user.organisation)

      visit activities_path(organisation_id: user.organisation)

      expect(page).to have_content I18n.t("page_title.activity.index")

      first_activity = activities.first
      last_activity = activities.last

      expect(page).to have_content first_activity.identifier

      expect(page).to have_content last_activity.identifier
    end

    scenario "an activity can be viewed" do
      activity = create(:project_activity, organisation: user.organisation)

      visit activities_path

      click_on(activity.title)
      click_on I18n.t("tabs.activity.details")

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

    context "when the organisation id query parameter is not the delivery_partners organisation id" do
      scenario "it defaults to showing the current users organisation activities" do
        another_delivery_partner = create(:delivery_partner_organisation)
        activity = create(:project_activity, organisation: user.organisation)

        visit activities_path(organisation_id: another_delivery_partner.id)

        expect(page).to have_content activity.identifier
      end
    end

    scenario "activities have human readable date format" do
      travel_to Time.zone.local(2020, 1, 29) do
        activity = create(:project_activity, planned_start_date: Date.new(2020, 2, 3),
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

    scenario "can go back to the previous page" do
      activity = create(:project_activity, organisation: user.organisation)

      visit organisation_activity_path(user.organisation, activity)

      click_on I18n.t("default.link.back")

      expect(page).to have_current_path(
        organisation_path(user.organisation)
      )
    end
  end
end
