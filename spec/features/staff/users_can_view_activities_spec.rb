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
      expect(page).to have_content t("page_title.activity.index")

      first_activity = activities.first
      last_activity = activities.last

      expect(page).to have_content first_activity.roda_identifier
      expect(page).to have_content last_activity.roda_identifier
      expect(page).to have_content another_activity.roda_identifier
    end

    scenario "they can view another organisations activities" do
      delivery_partner = create(:delivery_partner_organisation)
      activity = create(:programme_activity, extending_organisation: delivery_partner)

      visit activities_path(organisation_id: activity.organisation)

      expect(page).to have_content activity.roda_identifier
    end

    context "when an organisation id query parameter is not supplied" do
      scenario "it defaults to showing the current users organisation activities" do
        activity = create(:programme_activity, organisation: user.organisation)

        visit activities_path(organisation_id: "")

        expect(page).to have_content activity.roda_identifier
      end
    end

    context "when the organisation id query parameter is not the BEIS organisation id" do
      scenario "it shows the supplied organisation activities" do
        delivery_partner = create(:delivery_partner_organisation)
        activity = create(:programme_activity, extending_organisation: delivery_partner)

        visit activities_path(organisation_id: delivery_partner.id)
        expect(page).to have_content activity.roda_identifier
      end
    end

    context "when the organisation id query parameter is not a know organisation" do
      scenario "it defaults to showing the current users organisation activities" do
        activity = create(:programme_activity, extending_organisation: user.organisation)

        visit activities_path(organisation_id: "this-is-no-a-know-organisation")

        expect(page).to have_content activity.roda_identifier
      end
    end
  end

  context "when the user is signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    scenario "the page displays two tabs, one for current activities and one for historic ones" do
      create_list(:programme_activity, 5, extending_organisation: user.organisation)
      visit activities_path

      expect(page).to have_css(".govuk-tabs__tab", count: 2)
      expect(page).to have_css(".govuk-tabs__tab", text: "Current")
      expect(page).to have_css(".govuk-tabs__tab", text: "Historic")
    end

    scenario "they see a list of all current activities" do
      current_programme = create(:programme_activity, extending_organisation: user.organisation)
      current_project = create(:project_activity, organisation: user.organisation, parent: current_programme)
      another_current_project = create(:project_activity, :at_purpose_step, organisation: user.organisation, parent: current_programme)
      historic_programme = create(:programme_activity, extending_organisation: user.organisation, programme_status: "completed")
      historic_project = create(:project_activity, organisation: user.organisation, programme_status: "completed", parent: historic_programme)

      visit activities_path

      expect(page).to have_content(current_programme.title)
      expect(page).to have_content(current_programme.roda_identifier)
      expect(page).to have_content(current_project.title)
      expect(page).to have_content(current_project.roda_identifier)
      expect(page).to have_content(another_current_project.roda_identifier)

      expect(page).to_not have_content(historic_project.title)
      expect(page).to_not have_content(historic_project.roda_identifier)
    end

    scenario "they can choose to see a list of historic activities" do
      current_programme = create(:programme_activity, extending_organisation: user.organisation)
      current_project = create(:project_activity, organisation: user.organisation, parent: current_programme)
      historic_programme = create(:programme_activity, extending_organisation: user.organisation, programme_status: "completed")
      historic_project = create(:project_activity, organisation: user.organisation, programme_status: "completed", parent: historic_programme)
      another_historic_project = create(:project_activity, organisation: user.organisation, programme_status: "stopped", parent: historic_programme)

      visit activities_path
      click_on t("tabs.activities.historic")

      expect(page).to have_content(historic_project.title)
      expect(page).to have_content(another_historic_project.title)
      expect(page).to_not have_content(current_project.title)
    end

    scenario "they see a list of all their projects" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, organisation: user.organisation, parent: programme)

      visit activities_path

      within("#activity-#{project.id}") do
        expect(page).to have_link project.title, href: organisation_activity_path(project.organisation, project)
        expect(page).to have_content project.roda_identifier
      end
    end

    scenario "the list of projects is ordered by created_at (oldest first)" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, organisation: user.organisation, parent: programme)
      another_project = create(:project_activity, organisation: user.organisation, created_at: 2.days.ago, parent: programme)

      visit activities_path

      expect(page.find("table tbody tr:nth-child(2)")[:id]).to have_content("activity-#{another_project.id}")
      expect(page.find("table tbody tr:nth-child(3)")[:id]).to have_content("activity-#{project.id}")
    end

    scenario "they do not see a Publish to Iati column & status against projects" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, organisation: user.organisation, parent: programme)

      visit activities_path
      click_on project.title
      click_on t("tabs.activity.details")
      click_on programme.title
      click_on t("tabs.activity.children")

      expect(page).to_not have_content t("summary.label.activity.publish_to_iati.label")

      within("##{project.id}") do
        expect(page).to_not have_content t("summary.label.activity.publish_to_iati.true")
      end
    end

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
      expect(page).to have_link t("page_content.activity.implementing_organisation.button.new")
    end

    scenario "all activities can be viewed" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      activities = create_list(:project_activity, 5, organisation: user.organisation, parent: programme)

      visit activities_path(organisation_id: user.organisation)

      expect(page).to have_content t("page_title.activity.index")

      first_activity = activities.first
      last_activity = activities.last

      expect(page).to have_content first_activity.roda_identifier

      expect(page).to have_content last_activity.roda_identifier
    end

    scenario "an activity can be viewed" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      activity = create(:project_activity, parent: programme, organisation: user.organisation, sdgs_apply: true, sdg_1: 5)

      visit activities_path

      click_on(programme.title)
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

    context "when the organisation id query parameter is not the delivery_partners organisation id" do
      scenario "it defaults to showing the current users organisation activities" do
        another_delivery_partner = create(:delivery_partner_organisation)
        programme = create(:programme_activity, extending_organisation: user.organisation)
        activity = create(:project_activity, organisation: user.organisation, parent: programme)

        visit activities_path(organisation_id: another_delivery_partner.id)

        expect(page).to have_content activity.roda_identifier
      end
    end

    scenario "activities have human readable date format" do
      travel_to Time.zone.local(2020, 1, 29) do
        activity = create(:project_activity, planned_start_date: Date.new(2020, 2, 3),
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

    scenario "they can expand and collapse the rows to see child activities", js: true do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, organisation: user.organisation, parent: programme)
      third_party_project = create(:third_party_project_activity, organisation: user.organisation, parent: project)

      visit activities_path

      expect(page).to have_content(programme.title)
      expect(page).to have_content(programme.roda_identifier)

      expect(page).not_to have_css("#activity-#{project.id}", visible: true)
      expect(page).not_to have_css("#activity-#{third_party_project.id}", visible: true)

      click_on programme.title
      expect(page).to have_css("#activity-#{project.id}", visible: true)
      expect(page).not_to have_css("#activity-#{third_party_project.id}", visible: true)

      click_on project.title
      expect(page).to have_css("#activity-#{project.id}", visible: true)
      expect(page).to have_css("#activity-#{third_party_project.id}", visible: true)

      # Users can hide the expanded rows by clicking the parent activity
      click_on programme.title
      expect(page).not_to have_css("#activity-#{project.id}", visible: true)
      expect(page).not_to have_css("#activity-#{third_party_project.id}", visible: true)
    end
  end
end
