RSpec.feature "Users can view budgets on an activity page" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }

  context "when the activity is fund_level" do
    context "when the user is a fund manager" do
      let(:user) { create(:fund_manager, organisation: organisation) }

      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: organisation)
        budget = create(:budget, activity: fund_activity)

        visit organisations_path
        click_link organisation.name
        click_link fund_activity.title

        budget_details_are_present(budget)
      end
    end
  end

  context "when the activity is programme level" do
    let(:fund_activity) { create(:fund_activity, organisation: organisation) }
    let(:programme_activity) { create(:programme_activity, activity: fund_activity, organisation: organisation) }

    context "when the user is a fund manager" do
      let(:user) { create(:fund_manager, organisation: organisation) }

      scenario "budget information is shown on the page" do
        budget = create(:budget, activity: programme_activity)

        visit organisations_path
        click_link organisation.name
        click_link fund_activity.title
        click_link programme_activity.title

        budget_details_are_present(budget)
      end
    end

    context "when the user is a delivery partner" do
      let(:user) { create(:delivery_partner, organisation: organisation) }

      scenario "budget information is shown on the page" do
        budget = create(:budget, activity: programme_activity)

        visit organisation_path(organisation)
        click_link fund_activity.title
        click_link programme_activity.title

        budget_details_are_present(budget)
      end
    end
  end

  context "when the activity is project level" do
    let(:fund_activity) { create(:fund_activity, organisation: organisation) }
    let(:programme_activity) { create(:programme_activity, activity: fund_activity, organisation: organisation) }
    let(:project_activity) { create(:project_activity, activity: programme_activity, organisation: organisation) }

    context "when the user is a fund manager" do
      let(:user) { create(:fund_manager, organisation: organisation) }

      scenario "budget information is shown on the page" do
        budget = create(:budget, activity: project_activity)

        visit organisations_path
        click_link organisation.name
        click_link fund_activity.title
        click_link programme_activity.title

        click_link project_activity.title

        budget_details_are_present(budget)
      end
    end

    context "when the user is a delivery partner" do
      let(:user) { create(:delivery_partner, organisation: organisation) }

      scenario "budget information is shown on the page" do
        budget = create(:budget, activity: project_activity)

        visit organisation_path(organisation)
        click_link fund_activity.title
        click_link programme_activity.title
        click_link project_activity.title

        budget_details_are_present(budget)
      end
    end
  end

  def budget_details_are_present(budget)
    budget_presenter = BudgetPresenter.new(budget)
    expect(page).to have_content(budget_presenter.budget_type)
    expect(page).to have_content(budget_presenter.status)
    expect(page).to have_content(budget_presenter.period_start_date)
    expect(page).to have_content(budget_presenter.period_end_date)
    expect(page).to have_content(budget_presenter.value)
  end
end
