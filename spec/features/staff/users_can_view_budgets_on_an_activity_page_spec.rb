RSpec.feature "Users can view budgets on an activity page" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }

  context "when the activity is fund_level" do
    context "when the user is a fund manager" do
      let(:user) { create(:administrator, organisation: organisation) }

      scenario "budget information is not shown on the page" do
        fund_activity = create(:fund_activity, organisation: organisation)
        _budget = create(:budget)

        visit organisation_path(organisation)

        click_link fund_activity.title

        expect(page).to_not have_content(I18n.t("page_content.activity.budgets"))
      end
    end
  end

  context "when the activity is programme level" do
    let(:fund_activity) { create(:fund_activity, organisation: organisation) }
    let(:programme_activity) { create(:programme_activity, activity: fund_activity, organisation: organisation) }

    context "when the user is a fund manager" do
      let(:user) { create(:administrator, organisation: organisation) }

      scenario "budget information is shown on the page" do
        budget = create(:budget, activity: programme_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_path(organisation)

        click_link fund_activity.title
        click_link programme_activity.title

        expect(page).to have_content(budget_presenter.budget_type)
        expect(page).to have_content(budget_presenter.status)
        expect(page).to have_content(budget_presenter.period_start_date)
        expect(page).to have_content(budget_presenter.period_end_date)
        expect(page).to have_content(budget_presenter.value)
      end
    end
  end
end
