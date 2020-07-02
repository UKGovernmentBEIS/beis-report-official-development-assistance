RSpec.feature "Users can view budgets on an activity page" do
  before do
    authenticate!(user: user)
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    context "when the activity is fund_level" do
      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        budget = create(:budget, parent_activity: fund_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_path(user.organisation)

        click_link fund_activity.title

        budget_information_is_shown_on_page(budget_presenter)
      end

      scenario "budgets are shown in period date order, newest first" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        budget_1 = create(:budget, parent_activity: fund_activity, period_start_date: Date.today, period_end_date: Date.tomorrow)
        budget_2 = create(:budget, parent_activity: fund_activity, period_start_date: 1.year.ago, period_end_date: Date.yesterday)
        budget_3 = create(:budget, parent_activity: fund_activity, period_start_date: 2.years.ago, period_end_date: 1.year.ago)

        visit organisation_path(user.organisation)

        click_link fund_activity.title
        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[1]")[:id]).to eq(budget_1.id)
        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[2]")[:id]).to eq(budget_2.id)
        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[3]")[:id]).to eq(budget_3.id)
      end
    end

    context "when the activity is programme level" do
      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)

        budget = create(:budget, parent_activity: programme_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_path(user.organisation)

        click_link fund_activity.title
        click_on I18n.t("tabs.activity.details")
        click_link programme_activity.title

        budget_information_is_shown_on_page(budget_presenter)
      end
    end

    context "when the activity is project level" do
      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)
        project_activity = create(:project_activity, activity: programme_activity, organisation: user.organisation)

        budget = create(:budget, parent_activity: project_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_path(user.organisation)

        click_link fund_activity.title
        click_on I18n.t("tabs.activity.details")
        click_link programme_activity.title
        click_on I18n.t("tabs.activity.details")
        click_link project_activity.title

        budget_information_is_shown_on_page(budget_presenter)
      end

      scenario "a BEIS user cannot edit/create a budget" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)
        project_activity = create(:project_activity, activity: programme_activity, organisation: user.organisation)

        budget = create(:budget, parent_activity: project_activity)

        visit organisation_path(user.organisation)

        click_link fund_activity.title
        click_on I18n.t("tabs.activity.details")
        click_link programme_activity.title
        click_on I18n.t("tabs.activity.details")
        click_link project_activity.title

        expect(page).to_not have_content(I18n.t("page_content.budgets.button.create"))
        within("tr##{budget.id}") do
          expect(page).not_to have_content(I18n.t("default.link.edit"))
        end
      end
    end
  end

  context "when the user is a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity is programme level" do
      scenario "budget information is shown on the page" do
        programme_activity = create(:programme_activity, extending_organisation: user.organisation, organisation: user.organisation)

        budget = create(:budget, parent_activity: programme_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_path(user.organisation)

        click_link programme_activity.title

        budget_information_is_shown_on_page(budget_presenter)
      end

      scenario "budget information cannot be edited" do
        programme_activity = create(:programme_activity, extending_organisation: user.organisation, organisation: user.organisation)

        budget = create(:budget, parent_activity: programme_activity)

        visit organisation_path(user.organisation)

        click_link programme_activity.title

        within "##{budget.id}" do
          expect(page).to_not have_content I18n.t("default.link.edit")
        end
      end
    end

    context "when the activity is project level" do
      scenario "budget information is shown on the page" do
        programme_activity = create(:programme_activity, extending_organisation: user.organisation, organisation: user.organisation)
        project_activity = create(:project_activity, activity: programme_activity, organisation: user.organisation)

        budget = create(:budget, parent_activity: project_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_path(user.organisation)

        click_link programme_activity.title
        click_on I18n.t("tabs.activity.details")
        click_link project_activity.title

        budget_information_is_shown_on_page(budget_presenter)
      end

      scenario "a delivery partner can edit/create a budget" do
        programme_activity = create(:programme_activity, extending_organisation: user.organisation, organisation: user.organisation)
        project_activity = create(:project_activity, activity: programme_activity, organisation: user.organisation)

        budget = create(:budget, parent_activity: project_activity)

        visit organisation_path(user.organisation)

        click_link programme_activity.title
        click_on I18n.t("tabs.activity.details")
        click_link project_activity.title

        expect(page).to have_content(I18n.t("page_content.budgets.button.create"))
        within("tr##{budget.id}") do
          expect(page).to have_content(I18n.t("default.link.edit"))
        end
      end
    end
  end

  def budget_information_is_shown_on_page(budget_presenter)
    expect(page).to have_content(budget_presenter.budget_type)
    expect(page).to have_content(budget_presenter.status)
    expect(page).to have_content(budget_presenter.period_start_date)
    expect(page).to have_content(budget_presenter.period_end_date)
    expect(page).to have_content(budget_presenter.currency)
    expect(page).to have_content(budget_presenter.value)
  end
end
