RSpec.describe "Users can edit a planned disbursement" do
  context "when signed in as a deivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "they can edit a planned disbursement" do
      organisation = user.organisation
      project = create(:project_activity, organisation: user.organisation)
      editable_report = create(:report, state: :active, organisation: project.organisation, fund: project.associated_fund)
      planned_disbursement = create(:planned_disbursement, parent_activity: project, report: editable_report)

      visit organisation_activity_path(organisation, project)

      within "##{planned_disbursement.id}" do
        click_on "Edit"
      end

      expect(page).to have_http_status(:success)

      fill_in "Forecasted spend amount", with: "£20000"
      click_button "Submit"

      expect(page).to have_content t("action.planned_disbursement.update.success")
      expect(page).to have_content "£20,000"
    end

    scenario "the correct financial quarter and year are selected" do
      first_quarter_2018_2019 = "2018-04-01".to_date
      project = create(:project_activity, organisation: user.organisation)
      editable_report = create(:report, state: :active, organisation: project.organisation, fund: project.associated_fund)
      planned_disbursement = create(:planned_disbursement, parent_activity: project, report: editable_report, financial_quarter: 2, financial_year: 2018)

      travel_to first_quarter_2018_2019 do
        visit organisation_activity_path(project.organisation, project)
        within "##{planned_disbursement.id}" do
          click_on "Edit"
        end

        expect(page).to have_checked_field "Q2"
        expect(page).to have_select "Financial year", selected: "2018-2019"
      end
    end

    scenario "they do not see the edit link when they cannot edit" do
      activity = create(:project_activity, organisation: user.organisation)
      planned_disbursement = create(:planned_disbursement, parent_activity: activity)

      visit organisation_activity_path(activity.organisation, activity)

      expect(page).not_to have_link t("default.link.edit"),
        href: edit_activity_planned_disbursement_path(activity, planned_disbursement)
    end

    scenario "the action is recorded with public_activity" do
      PublicActivity.with_tracking do
        project = create(:project_activity, organisation: user.organisation)
        editable_report = create(:report, state: :active, organisation: project.organisation, fund: project.associated_fund)
        planned_disbursement = create(:planned_disbursement, parent_activity: project, report: editable_report)

        visit activities_path
        click_on(project.title)
        within("##{planned_disbursement.id}") do
          click_on(t("default.link.edit"))
        end

        fill_in_planned_disbursement_form(value: "2000.51")

        auditable_event = PublicActivity::Activity.find_by(trackable_id: planned_disbursement.id)
        expect(auditable_event.key).to eq "planned_disbursement.update"
        expect(auditable_event.owner_id).to eq user.id
      end
    end
  end
end
