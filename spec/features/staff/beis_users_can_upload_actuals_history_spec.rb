RSpec.feature "BEIS users upload actual history" do
  context "as a BEIS user" do
    let(:beis_user) { create(:beis_user) }
    let(:report) { create(:report) }

    before { authenticate!(user: beis_user) }

    scenario "they can see the actuals history upload interface" do
      visit report_actuals_path(report)

      expect(page).to have_content(t("actions.uploads.actual_histories.new_upload"))
    end
  end

  context "as a delvivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }
    let(:report) { create(:report, organisation: beis_user.organisation) }

    before { authenticate!(user: delivery_partner_user) }

    scenario "they cannot see the actuals history upload interface" do
      report = create(:report)

      visit report_actuals_path(report)

      expect(page).not_to have_content(t("actions.uploads.actual_histories.new_upload"))
    end
  end
end
