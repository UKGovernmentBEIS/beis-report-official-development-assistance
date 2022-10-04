RSpec.feature "Users can view an activity's financials" do
  context "when the user is signed in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    before do
      authenticate!(user: user)
    end

    after { logout }

    scenario "the activity financials can be viewed" do
      activity = create(:project_activity, organisation: user.organisation)
      actual = create(:actual, parent_activity: activity)
      budget = create(:budget, parent_activity: activity)

      visit organisation_activity_financials_path(activity.organisation, activity)
      within ".govuk-tabs__list-item--selected" do
        expect(page).to have_content "Financials"
      end
      expect(page).to have_content actual.value
      expect(page).to have_content budget.value
    end
  end
end
