RSpec.feature "Users can view budgets on an activity page" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:activity) { create(:activity, organisation: organisation) }

  context "when the user is a fund manager" do
    let(:user) { create(:fund_manager, organisation: organisation) }

    scenario "budget information is shown on the page" do
      budget = create(:budget, activity: activity)
      budget_presenter = BudgetPresenter.new(budget)

      visit organisations_path
      click_link organisation.name
      click_link activity.title

      expect(page).to have_content(budget_presenter.budget_type)
      expect(page).to have_content(budget_presenter.status)
      expect(page).to have_content(budget_presenter.period_start_date)
      expect(page).to have_content(budget_presenter.period_end_date)
      expect(page).to have_content(budget_presenter.value)
    end
  end
end
