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
        expect(page).to have_content programme.roda_identifier
      end

      scenario "the child programme activities are ordered by created_at (oldest first)" do
        fund = create(:fund_activity)
        programme_1 = create(:programme_activity,
          created_at: Date.yesterday,
          parent: fund)
        programme_2 = create(:programme_activity,
          created_at: Date.today,
          parent: fund)

        visit organisation_activity_children_path(fund.organisation, fund)

        expect(page.find("table.programmes  tbody tr:first-child")[:id]).to have_content(programme_1.id)
        expect(page.find("table.programmes  tbody tr:last-child")[:id]).to have_content(programme_2.id)
      end

      scenario "they do not see a Publish to Iati column & status against programmes" do
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund)

        visit organisation_activity_children_path(fund.organisation, fund)

        within(".programmes") do
          expect(page).to_not have_content t("summary.label.activity.publish_to_iati.label")
        end

        within("##{programme.id}") do
          expect(page).to_not have_content t("summary.label.activity.publish_to_iati.true")
        end
      end
    end

    context "and the activity is a programme" do
      scenario "they view a list of all child projects" do
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund)
        project = create(:project_activity, parent: programme)
        another_project = create(:project_activity, parent: programme)

        visit organisation_activity_children_path(programme.organisation, programme)

        within("##{project.id}") do
          expect(page).to have_link project.title, href: organisation_activity_path(project.organisation, project)
          expect(page).to have_content project.roda_identifier
          expect(page).to have_content project.parent.title
        end

        within("##{another_project.id}") do
          expect(page).to have_link another_project.title, href: organisation_activity_path(another_project.organisation, another_project)
          expect(page).to have_content another_project.roda_identifier
          expect(page).to have_content another_project.parent.title
        end
      end

      scenario "they see a Publish to Iati column & status against projects" do
        fund = create(:fund_activity)
        programme = create(:programme_activity, parent: fund)
        project = create(:project_activity, parent: programme)

        visit organisation_activity_children_path(programme.organisation, programme)

        within(".projects") do
          expect(page).to have_content t("summary.label.activity.publish_to_iati.label")
        end

        within("##{project.id}") do
          expect(page).to have_content "Yes"
        end
      end
    end

    context "whent the activity is a project" do
      scenario "they see a list of all their third-party projects" do
        project = create(:project_activity)
        third_party_project = create(:third_party_project_activity, parent: project)

        visit organisation_activity_children_path(project.organisation, project)

        within("##{third_party_project.id}") do
          expect(page).to have_link third_party_project.title, href: organisation_activity_path(third_party_project.organisation, third_party_project)
          expect(page).to have_content third_party_project.roda_identifier
          expect(page).to have_content third_party_project.parent.title
        end
      end

      scenario "they see a Publish to Iati column & status against third-party projects" do
        project = create(:project_activity)
        third_party_project = create(:third_party_project_activity, parent: project)

        visit organisation_activity_children_path(project.organisation, project)

        expect(page).to have_content t("summary.label.activity.publish_to_iati.label")

        within("##{third_party_project.id}") do
          expect(page).to have_content "Yes"
        end
      end
    end

    scenario "the activity financials can be viewed" do
      activity = create(:programme_activity, organisation: user.organisation)
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
      expect(page).to have_button t("page_content.organisation.button.create_activity")
    end

    scenario "the activity details tab can be viewed" do
      activity = create(:activity, organisation: user.organisation)

      visit organisation_activity_details_path(activity.organisation, activity)

      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Details"
      end
      activity_presenter = ActivityPresenter.new(activity)

      expect(page).to have_content activity_presenter.roda_identifier
      expect(page).to have_content activity_presenter.sector
      expect(page).to have_content activity_presenter.title
      expect(page).to have_content activity_presenter.description
      expect(page).to have_content activity_presenter.planned_start_date
      expect(page).to have_content activity_presenter.planned_end_date
      expect(page).to have_content activity_presenter.recipient_region
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

    scenario "they do not see a Publish to Iati column & status against third-party projects" do
      project = create(:project_activity, organisation: user.organisation)
      third_party_project = create(:third_party_project_activity, parent: project)

      visit organisation_activity_children_path(project.organisation, project)

      expect(page).to_not have_content t("summary.label.activity.publish_to_iati.label")

      within("##{third_party_project.id}") do
        expect(page).to_not have_content t("summary.label.activity.publish_to_iati.true")
      end
    end
  end
end
