RSpec.feature "Users can view budgets on an activity page" do
  before do
    authenticate!(user: user)
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    context "when the activity is fund_level" do
      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        create(:programme_activity, parent: fund_activity)
        budget = create(:budget, parent_activity: fund_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_activity_path(fund_activity.organisation, fund_activity)

        budget_information_is_shown_on_page(budget_presenter)
      end

      scenario "budgets are shown in period date order, newest first" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        create(:programme_activity, parent: fund_activity)
        budget_1 = create(:budget, parent_activity: fund_activity, financial_year: 2020)
        budget_2 = create(:budget, parent_activity: fund_activity, financial_year: 2019)
        budget_3 = create(:budget, parent_activity: fund_activity, financial_year: 2018)

        visit organisation_activity_path(fund_activity.organisation, fund_activity)

        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[1]")[:id]).to eq(budget_1.id)
        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[2]")[:id]).to eq(budget_2.id)
        expect(page.find(:xpath, "//table[@class = 'govuk-table budgets']/tbody/tr[3]")[:id]).to eq(budget_3.id)
      end
    end

    context "when the activity is programme level" do
      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)

        budget = create(:budget, parent_activity: programme_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_activity_path(programme_activity.organisation, programme_activity)

        budget_information_is_shown_on_page(budget_presenter)
      end
    end

    context "when the activity is project level" do
      let(:partner_org_user) { create(:delivery_partner_user) }
      scenario "budget information is shown on the page" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)
        project_activity = create(:project_activity, parent: programme_activity, organisation: partner_org_user.organisation)

        budget = create(:budget, parent_activity: project_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit organisation_activity_path(project_activity.organisation, project_activity)

        budget_information_is_shown_on_page(budget_presenter)
      end

      scenario "a BEIS user cannot edit/create a budget" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)
        project_activity = create(:project_activity, parent: programme_activity, organisation: partner_org_user.organisation)

        budget = create(:budget, parent_activity: project_activity)

        visit organisation_activity_path(project_activity.organisation, project_activity)

        expect(page).to_not have_content(t("page_content.budgets.button.create"))
        within("tr##{budget.id}") do
          expect(page).not_to have_content(t("default.link.edit"))
        end
      end
    end
  end

  context "when the user is a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity is programme level" do
      scenario "budget information is shown on the page" do
        programme_activity = create(:programme_activity, extending_organisation: user.organisation)
        project_activity = create(:project_activity, organisation: user.organisation, parent: programme_activity)
        budget = create(:budget, parent_activity: programme_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit activities_path
        within "#activity-#{project_activity.id}" do
          click_link t("table.body.activity.view_activity")
        end
        click_link t("tabs.activity.details")
        within(".activity-details") do
          click_link programme_activity.title
        end

        budget_information_is_shown_on_page(budget_presenter)
      end

      scenario "budget information cannot be edited" do
        programme_activity = create(:programme_activity, extending_organisation: user.organisation)

        budget = create(:budget, parent_activity: programme_activity)

        visit organisation_activity_path(programme_activity.organisation, programme_activity)

        within "##{budget.id}" do
          expect(page).to_not have_content t("default.link.edit")
        end
      end
    end

    context "when the activity is project level" do
      scenario "budget information is shown on the page" do
        programme_activity = create(:programme_activity, extending_organisation: user.organisation)
        project_activity = create(:project_activity, parent: programme_activity, organisation: user.organisation)

        budget = create(:budget, parent_activity: project_activity)
        budget_presenter = BudgetPresenter.new(budget)

        visit activities_path

        click_link programme_activity.title
        click_on t("tabs.activity.children")
        click_link project_activity.title

        budget_information_is_shown_on_page(budget_presenter)
      end

      scenario "a delivery partner can edit/create a budget" do
        programme_activity = create(:programme_activity, extending_organisation: user.organisation)
        report = create(:report, :active, organisation: user.organisation, fund: programme_activity.associated_fund)
        project_activity = create(:project_activity, parent: programme_activity, organisation: user.organisation)

        budget = create(:budget, parent_activity: project_activity, report_id: report.id)

        visit activities_path

        click_link programme_activity.title
        click_on t("tabs.activity.children")
        click_link project_activity.title

        expect(page).to have_content(t("page_content.budgets.button.create"))
        within("tr##{budget.id}") do
          expect(page).to have_content(t("default.link.edit"))
        end
      end
    end
  end

  def budget_information_is_shown_on_page(budget_presenter)
    expect(page).to have_content(budget_presenter.budget_type)
    expect(page).to have_content(budget_presenter.financial_year)
    expect(page).to have_content(budget_presenter.value)
    expect(page).to have_content(budget_presenter.providing_organisation_name)
  end
end
