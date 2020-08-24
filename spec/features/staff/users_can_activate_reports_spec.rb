RSpec.feature "Users can activate reports" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    scenario "they can activate a report" do
      report = create(:report, state: :inactive)

      visit report_path(report)
      click_link I18n.t("action.report.activate.button")
      click_button I18n.t("action.report.activate.confirm.button")

      expect(page).to have_content "complete"
      expect(report.reload.state).to eql "active"
    end

    context "when the report is already active" do
      scenario "it cannot be activated agian" do
        report = create(:report, state: :active)

        visit report_path(report)

        expect(page).not_to have_link "Activate report"

        visit edit_report_state_path(report)

        expect(page.status_code).to eql 401
      end
    end
  end

  context "signed in as a Delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they cannot activate a report" do
      report = create(:report, state: :inactive)

      visit report_path(report)

      expect(page).not_to have_link "Activate report"

      visit edit_report_state_path(report)

      expect(page.status_code).to eql 401
    end
  end
end
