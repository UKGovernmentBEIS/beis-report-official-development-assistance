RSpec.describe "Users can create a planned disbursement" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "they can add a planned disbursement" do
      project = create(:project_activity, :with_report, organisation: user.organisation)
      visit activities_path
      click_on project.title

      expect(page).to have_content t("page_content.activity.planned_disbursements")

      click_on t("page_content.planned_disbursements.button.create")

      expect(page).to have_content t("page_title.planned_disbursement.new")

      choose "Q1"
      select "2020-2021", from: "Financial year"
      fill_in "planned_disbursement[value]", with: "1000.00"
      click_button t("default.button.submit")

      expect(page).to have_current_path organisation_activity_financials_path(user.organisation, project)
      expect(page).to have_content t("action.planned_disbursement.create.success")
    end

    scenario "the current financial quarter and year are pre selected" do
      project = create(:project_activity, :with_report, organisation: user.organisation)
      first_quarter_2019_2020 = "2019-04-01".to_date

      travel_to first_quarter_2019_2020 do
        visit activities_path
        click_on project.title
        click_on t("page_content.planned_disbursements.button.create")

        expect(page).to have_checked_field "Q1"
        expect(page).to have_select "Financial year", selected: "2019-2020"
      end
    end

    scenario "the action is recorded with public_activity" do
      activity = create(:project_activity, :with_report, organisation: user.organisation)

      PublicActivity.with_tracking do
        visit activities_path

        click_on(activity.title)

        click_on(t("page_content.planned_disbursements.button.create"))

        fill_in_planned_disbursement_form

        planned_disbursement = PlannedDisbursement.last
        auditable_event = PublicActivity::Activity.last
        expect(auditable_event.key).to eq "planned_disbursement.create"
        expect(auditable_event.owner_id).to eq user.id
        expect(auditable_event.trackable_id).to eq planned_disbursement.id
      end
    end

    scenario "they do not see the add button when the activity is not editable" do
      activity = create(:project_activity, organisation: user.organisation)

      visit organisation_activity_path(activity.organisation, activity)

      expect(page).not_to have_link t("page_content.planned_disbursements.button.create"),
        href: new_activity_planned_disbursement_path(activity)
    end

    scenario "the planned disbursement is associated with the currently active report" do
      fund = create(:fund_activity)
      programme = create(:programme_activity, parent: fund)
      project = create(:project_activity, organisation: user.organisation, parent: programme)
      report = create(:report, :active, fund: fund, organisation: project.organisation)

      visit activities_path

      click_on(project.title)
      click_on(t("page_content.planned_disbursements.button.create"))

      fill_in_planned_disbursement_form

      planned_disbursement = PlannedDisbursement.last
      expect(planned_disbursement.report).to eq(report)
    end
  end

  context "when signed in as a beis user" do
    let(:beis_user) { create(:beis_user) }

    before { authenticate!(user: beis_user) }

    scenario "they cannot add a planned disbursement" do
      programme = create(:programme_activity)
      project = create(:project_activity, parent: programme)

      visit activities_path
      within "##{programme.id}" do
        click_on t("table.body.activity.view_activity")
      end
      click_on t("tabs.activity.children")
      click_on project.title

      expect(page).not_to have_link t("page_content.planned_disbursements.button.create"), href: new_activity_planned_disbursement_path(project)

      visit new_activity_planned_disbursement_path(project)

      expect(page).to have_content t("page_title.errors.not_authorised")
    end
  end
end
