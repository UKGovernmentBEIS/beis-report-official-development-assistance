RSpec.describe "Users can edit a planned disbursement" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "they can edit a planned disbursement" do
      organisation = user.organisation
      project = create(:project_activity, organisation: user.organisation)
      editable_report = create(:report, state: :active, organisation: project.organisation, fund: project.associated_fund)
      planned_disbursement = create(:planned_disbursement, parent_activity: project, report: editable_report, financial_year: editable_report.financial_year + 1)

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

        expect(page).to have_content("Edit forecasted spend for Q2 2018-2019")
      end
    end

    scenario "they do not see the edit link when they cannot edit" do
      activity = create(:project_activity, organisation: user.organisation)
      planned_disbursement = create(:planned_disbursement, parent_activity: activity)

      visit organisation_activity_path(activity.organisation, activity)

      expect(page).not_to have_link t("default.link.edit"),
        href: edit_activity_planned_disbursements_path(activity, planned_disbursement.financial_year, planned_disbursement.financial_quarter)
    end

    scenario "they receive an error message if the value is not a valid number" do
      organisation = user.organisation
      project = create(:project_activity, organisation: user.organisation)
      editable_report = create(:report, state: :active, organisation: project.organisation, fund: project.associated_fund)
      planned_disbursement = create(:planned_disbursement, parent_activity: project, report: editable_report, financial_year: editable_report.financial_year + 1)

      visit organisation_activity_path(organisation, project)

      within "##{planned_disbursement.id}" do
        click_on "Edit"
      end

      fill_in "Forecasted spend amount", with: ""
      click_button "Submit"

      expect(page).to have_content t("activerecord.errors.models.planned_disbursement.attributes.value.not_a_number")
    end

    scenario "the action is recorded with public_activity" do
      PublicActivity.with_tracking do
        project = create(:project_activity, organisation: user.organisation)
        editable_report = create(:report, state: :active, organisation: project.organisation, fund: project.associated_fund)
        planned_disbursement = create(:planned_disbursement, parent_activity: project, report: editable_report, financial_year: editable_report.financial_year + 1)

        visit activities_path
        click_on(project.title)
        within("##{planned_disbursement.id}") do
          click_on(t("default.link.edit"))
        end

        fill_in "planned_disbursement[value]", with: "2000.51"
        click_on(t("default.button.submit"))

        auditable_event = PublicActivity::Activity.find_by(trackable_id: planned_disbursement.id)
        expect(auditable_event.key).to eq "planned_disbursement.update"
        expect(auditable_event.owner_id).to eq user.id
      end
    end
  end
end
