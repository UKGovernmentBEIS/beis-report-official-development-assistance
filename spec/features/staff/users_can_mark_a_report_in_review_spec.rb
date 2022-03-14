RSpec.feature "Users can move reports into review" do
  context "signed in as a BEIS user" do
    let(:beis_user) { create(:beis_user) }

    before do
      authenticate!(user: beis_user)
    end

    scenario "they can mark a report as in review" do
      report = create(:report, state: :submitted)

      visit report_path(report)
      click_link "Mark as in review"
      click_button "Confirm"

      expect(page).to have_content "in review"
      expect(report.reload.state).to eql "in_review"
    end

    context "when the report is already in_review" do
      scenario "it cannot be set in review" do
        report = create(:report, state: :in_review)

        visit report_path(report)

        expect(page).not_to have_link "Mark as in review"
      end
    end
  end

  context "signed in as a Delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: delivery_partner_user)
    end

    scenario "they cannot mark a report as in review" do
      report = create(:report, state: :submitted)

      visit report_path(report)

      expect(page).not_to have_link "Mark as in review"

      visit edit_report_state_path(report)

      expect(page.status_code).to eql 401
    end
  end
end
