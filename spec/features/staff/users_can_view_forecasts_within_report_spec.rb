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
    end
  end
end
