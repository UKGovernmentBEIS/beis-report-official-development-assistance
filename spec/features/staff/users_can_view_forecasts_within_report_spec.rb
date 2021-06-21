RSpec.feature "Users can view forecasts in tab within a report" do
  context "as a Delivery Partner user" do
    let(:organisation) { create(:delivery_partner_organisation) }
    let(:user) { create(:delivery_partner_user, organisation: organisation) }

    before do
      authenticate!(user: user)
    end

    def expect_to_see_a_table_of_forecasts_grouped_by_activity(activities)
      expect(page).to have_content(
        t("page_content.tab_content.forecasts.per_activity_heading")
      )

      forecasts = ForecastOverview.new(activities.map(&:id))
        .latest_values
        .map { |f| ForecastPresenter.new(f) }

      fail "We expect some activities to be present" if activities.none?

      activities.each do |activity|
        within "#activity_#{activity.id}" do
          expect(page).to have_content(activity.title)
          expect(page).to have_content(activity.roda_identifier)

          fail "We expect some forecasts to be present" if forecasts.none?

          within ".forecasts" do
            forecasts.each do |forecast|
              expect(page).to have_content(forecast.value)
              expect(page).to have_content(forecast.financial_quarter_and_year)
            end
          end
        end
      end
    end

    def expect_to_see_total_of_forecasted_amounts(activities)
      forecasts = ForecastOverview.new(activities.map(&:id)).latest_values

      within ".totals" do
        expect(page).to have_content(
          ActionController::Base.helpers.number_to_currency(forecasts.sum(&:value), unit: "£")
        )
      end
    end

    scenario "the report contains a _forecasts_ tab" do
      programme = create(:programme_activity)

      project = create(:project_activity, organisation: organisation, parent: programme)

      report = create(
        :report,
        :active,
        organisation: organisation,
        fund: programme.parent,
        financial_quarter: 3,
        financial_year: 2020,
      )

      activities = 2.times.map {
        create(
          :third_party_project_activity,
          organisation: organisation,
          parent: project
        ).tap do |activity|
          ForecastHistory.new(
            activity,
            financial_quarter: 4,
            financial_year: 2020,
            user: user
          ).set_value(50_000)

          ForecastHistory.new(
            activity,
            financial_quarter: 1,
            financial_year: 2021,
            user: user
          ).set_value(75_000)
        end
      }

      visit report_path(report.id)

      click_link "Forecasts"

      expect(page).to have_content(t("page_content.tab_content.forecasts.heading"))
      expect(page).to have_link(t("action.forecast.upload.link"))

      # guidance with 2 links
      expect(page).to have_content("This page shows all the new or updated forecasts")
      expect(page).to have_link("uploading new activities")
      expect(page).to have_link("uploading updates to activities")

      # forecasts per activity
      expect_to_see_a_table_of_forecasts_grouped_by_activity(activities)

      expect_to_see_total_of_forecasted_amounts(activities)
    end

    context "report is in a state where upload is not permissable" do
      scenario "the upload facility is not present" do
        report = create(:report, state: :approved, organisation: organisation, description: nil)

        visit report_path(report.id)

        click_link "Forecasts"

        expect(page).not_to have_link(t("action.forecast.upload.link"))
      end
    end
  end
end
