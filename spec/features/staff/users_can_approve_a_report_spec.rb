RSpec.feature "Users can approve reports" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    scenario "they can mark a report as approved" do
      report = create(:report, state: :in_review)

      visit report_path(report)
      click_link t("action.report.approve.button")
      click_button t("action.report.approve.confirm.button")

      expect(page).to have_content "approved"
      expect(report.reload.state).to eql "approved"
    end

    context "when the report is already approved" do
      scenario "it cannot be approved" do
        report = create(:report, state: :approved)

        visit report_path(report)

        expect(page).not_to have_link t("action.report.approve.button")
      end
    end
  end

  context "signed in as a Delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they cannot mark a report as approved" do
      report = create(:report, state: :in_review)

      visit report_path(report)

      expect(page).not_to have_link t("action.report.approve.button")

      visit edit_report_state_path(report)

      expect(page.status_code).to eql 401
    end
  end
end
