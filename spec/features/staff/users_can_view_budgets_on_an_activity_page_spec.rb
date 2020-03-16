RSpec.feature "Users can view budgets on an activity page" do
  before do
    authenticate!(user: user)
  end

  context "when the activity is fund_level" do
    context "when the user belongs to BEIS" do
      let(:user) { create(:beis_user) }

      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        budget = create(:budget, activity: fund_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_path(user.organisation)

        click_link fund_activity.title

        expect(page).to have_content(budget_presenter.budget_type)
        expect(page).to have_content(budget_presenter.status)
        expect(page).to have_content(budget_presenter.period_start_date)
        expect(page).to have_content(budget_presenter.period_end_date)
        expect(page).to have_content(budget_presenter.currency)
        expect(page).to have_content(budget_presenter.value)
      end

      scenario "budgets are shown in period date order, newest first" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        budget_1 = create(:budget, activity: fund_activity, period_start_date: Date.today, period_end_date: Date.tomorrow)
        budget_2 = create(:budget, activity: fund_activity, period_start_date: 1.year.ago, period_end_date: Date.yesterday)
        budget_3 = create(:budget, activity: fund_activity, period_start_date: 2.years.ago, period_end_date: 1.year.ago)

        visit organisation_path(user.organisation)

        click_link fund_activity.title
        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[1]")[:id]).to eq(budget_1.id)
        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[2]")[:id]).to eq(budget_2.id)
        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[3]")[:id]).to eq(budget_3.id)
      end
    end
  end

  context "when the activity is programme level" do
    context "when the user belongs to BEIS" do
      let(:user) { create(:beis_user) }

      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)

        budget = create(:budget, activity: programme_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_path(user.organisation)

        click_link fund_activity.title
        click_link programme_activity.title

        expect(page).to have_content(budget_presenter.budget_type)
        expect(page).to have_content(budget_presenter.status)
        expect(page).to have_content(budget_presenter.period_start_date)
        expect(page).to have_content(budget_presenter.period_end_date)
        expect(page).to have_content(budget_presenter.currency)
        expect(page).to have_content(budget_presenter.value)
      end
    end
  end
end
