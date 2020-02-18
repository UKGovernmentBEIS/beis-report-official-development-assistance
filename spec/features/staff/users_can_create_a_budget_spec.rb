RSpec.describe "Users can create a budget" do
  before { authenticate!(user: user) }

  context "when signed in as BEIS user" do
    let(:user) { create(:beis_user) }

    context "on a fund level activity" do
      scenario "cannot create a budget on a fund" do
        fund_activity = create(:fund_activity, organisation: user.organisation)

        visit organisation_path(user.organisation)
        click_on(fund_activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(I18n.t("form.budget.create.success"))
      end
    end

    context "on a programme level activity" do
      scenario "successfully creates a budget" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)

        visit organisation_path(user.organisation)
        click_on(programme_activity.activity.title)
        click_on(programme_activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(I18n.t("form.budget.create.success"))
      end

      scenario "sees validation errors for missing attributes" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)

        visit organisation_path(user.organisation)

        click_on(programme_activity.activity.title)
        click_on(programme_activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

        click_button I18n.t("generic.button.submit")

        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Budget type can't be blank")
        expect(page).to have_content("Status can't be blank")
        expect(page).to have_content("Period start date can't be blank")
        expect(page).to have_content("Period end date can't be blank")
        expect(page).to have_content("Value is not included in the list")
      end
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    context "on a project level activity" do
      scenario "successfully creates a budget" do
        fund_activity = create(:fund_activity)
        programme_activity = create(:programme_activity, activity: fund_activity)
        project_activity = create(:project_activity, activity: programme_activity, organisation: user.organisation)

        visit organisation_path(user.organisation)

        click_on(programme_activity.title)
        click_on(project_activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(I18n.t("form.budget.create.success"))
      end
    end
  end

  def fill_in_and_submit_budget_form
    choose("budget[budget_type]", option: "original")
    choose("budget[status]", option: "indicative")
    fill_in "budget[period_start_date(3i)]", with: "01"
    fill_in "budget[period_start_date(2i)]", with: "01"
    fill_in "budget[period_start_date(1i)]", with: "2020"
    fill_in "budget[period_end_date(3i)]", with: "01"
    fill_in "budget[period_end_date(2i)]", with: "01"
    fill_in "budget[period_end_date(1i)]", with: "2021"
    fill_in "budget[value]", with: "1000.00"
    click_button I18n.t("generic.button.submit")
  end
end
