RSpec.describe "Users can delete a planned disbursement" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "the history is deleted" do
      PublicActivity.with_tracking do
        organisation = user.organisation
        project = create(:project_activity, organisation: user.organisation)
        editable_report = create(:report, state: :active, organisation: project.organisation, fund: project.associated_fund)
        planned_disbursement = create(:planned_disbursement, parent_activity: project, report: editable_report, financial_year: editable_report.financial_year + 1)

        visit organisation_activity_path(organisation, project)

        within "##{planned_disbursement.id}" do
          click_on "Edit"
        end

        click_on t("default.button.delete")

        expect(page).to have_title t("document_title.activity.financials", name: project.title)
        expect(page).to have_content t("action.planned_disbursement.destroy.success")

        expect(page).to_not have_selector "##{planned_disbursement.id}"
      end
    end
  end
end
