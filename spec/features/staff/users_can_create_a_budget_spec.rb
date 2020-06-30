RSpec.describe "Users can create a budget" do
  before { authenticate!(user: user) }

  context "when signed in as BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      scenario "successfully creates a budget" do
        fund_activity = create(:fund_activity, organisation: user.organisation)

        visit organisation_path(user.organisation)
        click_on(fund_activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(I18n.t("action.budget.create.success"))
      end

      scenario "budget creation is tracked with public_activity" do
        fund_activity = create(:fund_activity, organisation: user.organisation)

        PublicActivity.with_tracking do
          visit organisation_path(user.organisation)
          click_on(fund_activity.title)

          click_on(I18n.t("page_content.budgets.button.create"))

          fill_in_and_submit_budget_form

          budget = Budget.last
          auditable_event = PublicActivity::Activity.last
          expect(auditable_event.key).to eq "budget.create"
          expect(auditable_event.owner_id).to eq user.id
          expect(auditable_event.trackable_id).to eq budget.id
        end
      end
    end

    context "on a programme level activity" do
      scenario "successfully creates a budget" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)

        visit organisation_path(user.organisation)
        click_on(programme_activity.parent_activity.title)
        click_on I18n.t("tabs.activity.details")
        click_on(programme_activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(I18n.t("action.budget.create.success"))
      end

      scenario "sees validation errors for missing attributes" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)

        visit organisation_path(user.organisation)

        click_on(programme_activity.parent_activity.title)
        click_on I18n.t("tabs.activity.details")
        click_on(programme_activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

        click_button I18n.t("default.button.submit")

        expect(page).to have_content("There is a problem")
        expect(page).to have_content("Budget type can't be blank")
        expect(page).to have_content("Status can't be blank")
        expect(page).to have_content("Period start date can't be blank")
        expect(page).to have_content("Period end date can't be blank")
        expect(page).to have_content I18n.t("activerecord.errors.models.budget.attributes.value.inclusion")
      end
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }

    context "on a programme level activity" do
      scenario "they can view but not create budgets" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity,
          activity: fund_activity,
          organisation: user.organisation,
          extending_organisation: user.organisation)

        visit organisation_path(user.organisation)
        click_on(programme_activity.title)

        expect(page).to have_content(I18n.t("page_content.activity.budgets"))
        expect(page).not_to have_content(I18n.t("page_content.budgets.button.create"))
      end
    end

    context "on a project level activity" do
      scenario "successfully creates a budget" do
        fund_activity = create(:fund_activity)
        programme_activity = create(:programme_activity,
          activity: fund_activity,
          extending_organisation: user.organisation)
        project_activity = create(:project_activity,
          activity: programme_activity,
          organisation: user.organisation)

        visit organisation_path(user.organisation)

        click_on(programme_activity.title)
        click_on I18n.t("tabs.activity.details")
        click_on(project_activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(I18n.t("action.budget.create.success"))
      end
    end
  end

  def fill_in_and_submit_budget_form
    choose("budget[budget_type]", option: "1")
    choose("budget[status]", option: "1")
    fill_in "budget[period_start_date(3i)]", with: "01"
    fill_in "budget[period_start_date(2i)]", with: "01"
    fill_in "budget[period_start_date(1i)]", with: "2020"
    fill_in "budget[period_end_date(3i)]", with: "31"
    fill_in "budget[period_end_date(2i)]", with: "12"
    fill_in "budget[period_end_date(1i)]", with: "2020"
    select "Pound Sterling", from: "budget[currency]"
    fill_in "budget[value]", with: "1000.00"
    click_button I18n.t("default.button.submit")
  end
end
