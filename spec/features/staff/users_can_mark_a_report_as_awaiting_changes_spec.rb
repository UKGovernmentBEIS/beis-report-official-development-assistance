RSpec.feature "Users can move reports into awaiting changes & view reports awaiting changes" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    scenario "they can mark a report as awaiting changes" do
      report = create(:report, state: :in_review)

      visit report_path(report)
      click_link t("action.report.request_changes.button")
      click_button t("action.report.request_changes.confirm.button")

      expect(page).to have_content "awaiting changes"
      expect(report.reload.state).to eql "awaiting_changes"
    end

    context "when the report is already awaiting changes" do
      scenario "it cannot be set in review" do
        report = create(:report, state: :awaiting_changes)

        visit report_path(report)

        expect(page).not_to have_link t("action.report.request_changes.button")
      end
    end
  end

  context "signed in as a Delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they cannot mark a report as in awaiting changes" do
      report = create(:report, state: :in_review, organisation: delivery_partner_user.organisation)

      visit report_path(report)

      expect(page).not_to have_link t("action.report.request_changes.button")
    end
  end
end
