RSpec.describe "Users can edit a forecast" do
  context "when signed in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }
    let(:programme) { create(:programme_activity, extending_organisation: user.organisation) }
    let(:project) { create(:project_activity, organisation: user.organisation, parent: programme) }
    let(:forecast) { ForecastOverview.new(project).latest_values.first }
    let(:reporting_cycle) { ReportingCycle.new(project, 1, 2018) }
    let(:history) { ForecastHistory.new(project, financial_quarter: 4, financial_year: 2018) }

    before do
      authenticate!(user: user)
      reporting_cycle.tick
      history.set_value(40)
    end

    after { logout }

    scenario "they can edit a forecast" do
      visit organisation_activity_path(project.organisation, project)

      within "##{forecast.id}" do
        click_on "Edit"
      end

      expect(page).to have_http_status(:success)

      fill_in "Forecasted spend amount", with: "£20000"

      expect { click_button "Submit" }.to not_create_a_historical_event

      expect(page).to have_content t("action.forecast.update.success")
      expect(page).to have_content "£20,000"
    end

    scenario "a historical event is created if the original forecast part of an approved report" do
      reporting_cycle.tick

      visit organisation_activity_path(project.organisation, project)

      within "##{forecast.id}" do
        click_on "Edit"
      end

      fill_in "Forecasted spend amount", with: "£20000"

      expect { click_button "Submit" }.to create_a_historical_forecast_event(
        financial_quarter: FinancialQuarter.new(2018, 4),
        activity: project,
        previous_value: 40,
        new_value: 20000,
        report: Report.editable_for_activity(project)
      )

      click_on I18n.t("tabs.activity.historical_events")

      expect(page).to have_content("Revising a forecast for #{FinancialQuarter.new(2018, 4)}")
    end

    scenario "the correct financial quarter and year are selected" do
      visit organisation_activity_path(project.organisation, project)
      within "##{forecast.id}" do
        click_on "Edit"
      end

      expect(page).to have_content("Edit forecasted spend for FQ4 2018-2019")
    end

    scenario "they do not see the edit link when they cannot edit" do
      Report.update_all(state: :approved)

      visit organisation_activity_path(project.organisation, project)

      expect(page).not_to have_link t("default.link.edit"),
        href: edit_activity_forecasts_path(project, forecast.financial_year, forecast.financial_quarter)
    end

    scenario "they receive an error message if the value is not a valid number" do
      visit organisation_activity_path(project.organisation, project)

      within "##{forecast.id}" do
        click_on "Edit"
      end

      fill_in "Forecasted spend amount", with: ""
      click_button "Submit"

      expect(page).to have_content t("activerecord.errors.models.forecast.attributes.value.not_a_number")
    end
  end
end
