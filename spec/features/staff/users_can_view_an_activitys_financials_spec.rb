RSpec.feature "Users can view an activitys financials" do
  context "when the user is signed in as a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    before do
      authenticate!(user: user)
    end

    scenario "the activity financials can be viewed" do
      activity = create(:project_activity, organisation: user.organisation)
      transaction = create(:transaction, parent_activity: activity)
      budget = create(:budget, parent_activity: activity)

      visit organisation_activity_financials_path(activity.organisation, activity)
      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Financials"
      end
      expect(page).to have_content transaction.value
      expect(page).to have_content budget.value
    end
  end
end
