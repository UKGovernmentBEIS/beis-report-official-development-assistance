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
      activities.each do |activity|
        within "#activity_#{activity.id}" do
          expect(page).to have_content(activity.title)
          expect(page).to have_content(activity.roda_identifier)
        end
      end
    end

    scenario "the report contains a _forecasts_ tab" do
      programme = create(:programme_activity)

      report = create(:report, :active, organisation: organisation, fund: programme.parent)
      project = create(:project_activity, organisation: organisation, parent: programme)

      activities = 2.times.map {
        create(:third_party_project_activity, organisation: organisation, parent: project)
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
