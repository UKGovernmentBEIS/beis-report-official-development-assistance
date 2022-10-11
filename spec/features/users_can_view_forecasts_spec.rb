RSpec.describe "Users can view forecasts" do
  def create_forecast(activity)
    ReportingCycle.new(activity, 1, 2018).tick
    ForecastHistory.new(activity, financial_quarter: 2, financial_year: 2018).set_value(20)
    ForecastOverview.new(activity).latest_values.last
  end

  context "when signed in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }
    before { authenticate!(user: user) }
    after { logout }

    scenario "they can view forecasts on projects" do
      project = create(:project_activity, organisation: user.organisation)
      forecast = create_forecast(project)

      visit organisation_activity_path(user.organisation, project)

      expect(page).to have_content t("page_content.activity.forecasts")
      expect(page).to have_selector "##{forecast.id}"
    end

    scenario "they can view forecasts on third-party projects" do
      third_party_project = create(:third_party_project_activity, organisation: user.organisation)
      forecast = create_forecast(third_party_project)

      visit organisation_activity_path(user.organisation, third_party_project)

      expect(page).to have_content t("page_content.activity.forecasts")
      expect(page).to have_selector "##{forecast.id}"
    end
  end

  context "when signed in as a beis user" do
    let(:beis_user) { create(:beis_user) }
    before { authenticate!(user: beis_user) }
    after { logout }

    scenario "they can view forecasts on projects" do
      project = create(:project_activity)
      forecast = create_forecast(project)

      visit organisation_activity_path(beis_user.organisation, project)

      expect(page).to have_content t("page_content.activity.forecasts")
      expect(page).to have_selector "##{forecast.id}"
    end

    scenario "they can view forecasts on third-party projects" do
      third_party_project = create(:third_party_project_activity)
      forecast = create_forecast(third_party_project)

      visit organisation_activity_path(beis_user.organisation, third_party_project)

      expect(page).to have_content t("page_content.activity.forecasts")
      expect(page).to have_selector "##{forecast.id}"
    end
  end
end
