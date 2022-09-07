RSpec.describe "Users can create a forecast" do
  context "when signed in as a partner organisation user" do
    let(:user) { create(:delivery_partner_user) }

    before { authenticate!(user: user) }

    scenario "they can add a forecast" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)

      visit organisation_activity_path(project.organisation, project)

      expect(page).to have_content t("page_content.activity.forecasts")

      click_on t("page_content.forecasts.button.create")

      expect(page).to have_content t("page_title.forecast.new")

      fill_in_forecast_form_for_activity(project)

      expect(page).to have_current_path organisation_activity_path(user.organisation, project)
      expect(page).to have_content t("action.forecast.create.success")
    end

    scenario "they can go back if they try to add a forecast in error" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)
      visit activities_path
      click_on project.title

      click_on t("page_content.forecasts.button.create")

      click_on t("form.link.activity.back")

      expect(page).to have_title t("document_title.activity.financials", name: project.title)
    end

    context "when we are in the first quarter" do
      scenario "the current financial quarter and year are pre selected" do
        travel_to_quarter(1, 2019) do
          programme = create(:programme_activity, extending_organisation: user.organisation)
          project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)
          visit activities_path
          click_on project.title
          click_on t("page_content.forecasts.button.create")

          expect(page).to have_checked_field "Q1"
          expect(page).to have_select "Financial year", selected: "2019-2020"
        end
      end
    end

    context "when we are in the fourth quarter" do
      scenario "the current financial quarter and year are pre selected" do
        travel_to_quarter(4, 2019) do
          programme = create(:programme_activity, extending_organisation: user.organisation)
          project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)
          visit activities_path
          click_on project.title
          click_on t("page_content.forecasts.button.create")

          expect(page).to have_checked_field "Q4"
          expect(page).to have_select "Financial year", selected: "2019-2020"
        end
      end
    end

    scenario "they do not see the add button when the activity is not editable" do
      activity = create(:project_activity, organisation: user.organisation)

      visit organisation_activity_path(activity.organisation, activity)

      expect(page).not_to have_link t("page_content.forecasts.button.create"),
        href: new_activity_forecast_path(activity)
    end

    scenario "the forecast is associated with the currently active report" do
      fund = create(:fund_activity)
      programme = create(:programme_activity, parent: fund, extending_organisation: user.organisation)
      project = create(:project_activity, organisation: user.organisation, parent: programme)
      report = create(:report, :active, fund: fund, organisation: project.organisation)

      visit activities_path

      click_on(project.title)
      click_on(t("page_content.forecasts.button.create"))

      fill_in_forecast_form_for_activity(project)

      forecast = ForecastOverview.new(project).latest_values.last
      expect(forecast.report).to eq(report)
    end

    scenario "they cannot add a forecast when no editable report exists" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)
      Report.update_all(state: :approved)

      visit activities_path
      click_on project.title

      expect(page).to have_content t("page_content.activity.forecasts")
      expect(page).not_to have_link t("page_content.forecasts.button.create")
    end

    scenario "they receive an error message if the forecast is not in the future" do
      travel_to_quarter(3, 2020) do
        programme = create(:programme_activity, extending_organisation: user.organisation)
        project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)
        visit activities_path
        click_on project.title

        click_on t("page_content.forecasts.button.create")

        report = Report.editable_for_activity(project)
        year = report.financial_year

        fill_in_forecast_form(
          financial_quarter: "Q1",
          financial_year: "#{year}-#{year + 1}"
        )

        expect(page).to have_content t("activerecord.errors.models.forecast.attributes.financial_quarter.in_the_past")
      end
    end

    scenario "they receive an error message if the value is not a valid number" do
      programme = create(:programme_activity, extending_organisation: user.organisation)
      project = create(:project_activity, :with_report, organisation: user.organisation, parent: programme)
      visit activities_path
      click_on project.title

      click_on t("page_content.forecasts.button.create")

      report = Report.editable_for_activity(project)
      year = report.financial_year

      fill_in_forecast_form(
        financial_quarter: "Q#{report.financial_quarter}",
        financial_year: "#{year + 1}-#{year + 2}",
        value: ""
      )

      expect(page).to have_content t("activerecord.errors.models.forecast.attributes.value.not_a_number")
    end
  end

  context "when signed in as a beis user" do
    let(:beis_user) { create(:beis_user) }

    before { authenticate!(user: beis_user) }

    scenario "they cannot add a forecast" do
      programme = create(:programme_activity)
      project = create(:project_activity, parent: programme)

      visit organisation_activity_path(project.organisation, project)

      expect(page).not_to have_link t("page_content.forecasts.button.create"), href: new_activity_forecast_path(project)

      visit new_activity_forecast_path(project)

      expect(page).to have_content t("page_title.errors.not_authorised")
    end
  end
end
