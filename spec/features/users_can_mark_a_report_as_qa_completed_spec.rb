RSpec.feature "Users can mark reports as QA completed" do
  context "signed in as a BEIS user" do
    let!(:beis_user) { create(:beis_user) }

    before { authenticate!(user: beis_user) }
    after { logout }

    scenario "they can mark a report as QA completed" do
      report = create(:report, state: :in_review)

      visit report_path(report)
      click_link t("action.report.mark_qa_completed.button")
      click_button t("default.button.confirm")

      expect(page).to have_content "QA completed"
      expect(report.reload.state).to eql "qa_completed"
    end

    context "when the report is already marked as QA completed" do
      scenario "it cannot be marked as QA completed" do
        report = create(:report, state: :qa_completed)

        visit report_path(report)

        expect(page).not_to have_link t("action.report.mark_qa_completed.button")
      end
    end
  end

  context "signed in as a partner organisation user" do
    let(:partner_org_user) { create(:partner_organisation_user) }

    before { authenticate!(user: partner_org_user) }
    after { logout }

    scenario "they cannot mark a report as QA completed" do
      report = create(:report, state: :in_review, organisation: partner_org_user.organisation)

      visit report_path(report)

      expect(page).not_to have_link t("action.report.mark_qa_completed.button")
    end
  end
end
