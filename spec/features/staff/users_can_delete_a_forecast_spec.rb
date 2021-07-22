RSpec.describe "Users can delete a forecast" do
  context "when signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "the history is deleted" do
      organisation = user.organisation
      project = create(:project_activity, organisation: user.organisation)

      ReportingCycle.new(project, 1, 2018).tick
      ForecastHistory.new(project, financial_quarter: 2, financial_year: 2018).set_value(50)
      forecast = ForecastOverview.new(project).latest_values.last

      visit organisation_activity_path(organisation, project)

      within "##{forecast.id}" do
        click_on "Edit"
      end

      click_on t("default.button.delete")

      expect(page).to have_title t("document_title.activity.financials", name: project.title)
      expect(page).to have_content t("action.forecast.destroy.success")

      expect(page).to_not have_selector "##{forecast.id}"
    end
  end
end
