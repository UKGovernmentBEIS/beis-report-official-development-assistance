RSpec.feature "Users can move reports into review" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    after { logout }

    scenario "they can mark a report as in review" do
      report = create(:report, state: :submitted)

      visit report_path(report)
      click_link t("action.report.in_review.button")
      click_button t("action.report.in_review.confirm.button")

      expect(page).to have_content "in review"
      expect(report.reload.state).to eql "in_review"
    end

    context "when the report is already in_review" do
      scenario "it cannot be set in review" do
        report = create(:report, state: :in_review)

        visit report_path(report)

        expect(page).not_to have_link t("action.report.in_review.button")
      end
    end
  end

  context "signed in as a partner organisation user" do
    let(:partner_org_user) { create(:partner_organisation_user) }

    before do
      authenticate!(user: partner_org_user)
    end

    after { logout }

    scenario "they cannot mark a report as in review" do
      report = create(:report, state: :submitted)

      visit report_path(report)

      expect(page).not_to have_link t("action.report.in_review.button")

      visit edit_report_state_path(report)

      expect(page).to have_http_status(:unauthorized)
    end
  end
end
