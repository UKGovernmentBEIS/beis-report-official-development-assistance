RSpec.feature "Users can view forecasts in tab within a report" do
  context "as a Delivery Partner user" do
    let(:organisation) { create(:delivery_partner_organisation) }
    let(:user) { create(:delivery_partner_user, organisation: organisation) }

    before do
      authenticate!(user: user)
    end

    scenario "the report contains a _forecasts_ tab" do
      report = create(:report, :active, organisation: organisation, description: nil)

      visit report_path(report.id)

      click_link "Forecasts"

      expect(page).to have_content(t("page_content.tab_content.forecasts.heading"))
      expect(page).to have_link(t("action.forecast.upload.link"))

      # guidance with 2 links
      expect(page).to have_content("This page shows all the new or updated forecasts")
      expect(page).to have_link("uploading new activities")
      expect(page).to have_link("uploading updates to activities")

      # forecasts per activity
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
