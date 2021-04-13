RSpec.describe "Users can create a budget" do
  before { authenticate!(user: user) }

  context "when signed in as BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      scenario "successfully creates a budget" do
        fund_activity = create(:fund_activity, organisation: user.organisation)

        visit activities_path
        click_on(fund_activity.title)

        click_on(t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(t("action.budget.create.success"))
      end

      scenario "a new budget has its funding type set to that of its parent activity's source fund" do
        activity = create(:programme_activity, :gcrf_funded, organisation: user.organisation)

        visit activities_path
        click_on(activity.title)
        click_on(t("page_content.budgets.button.create"))

        expect(page.has_checked_field?("budget-budget-type-#{activity.source_fund_code}-field")).to be_truthy
      end

      scenario "budget creation is tracked with public_activity" do
        fund_activity = create(:fund_activity, organisation: user.organisation)

        PublicActivity.with_tracking do
          visit activities_path
          click_on(fund_activity.title)

          click_on(t("page_content.budgets.button.create"))

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
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)

        visit activities_path
        click_on(programme_activity.parent.title)
        click_on t("tabs.activity.children")
        click_on(programme_activity.title)

        click_on(t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(t("action.budget.create.success"))
      end

      scenario "sees validation errors for missing attributes" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)

        visit activities_path

        click_on(programme_activity.parent.title)
        click_on t("tabs.activity.children")
        click_on(programme_activity.title)

        click_on(t("page_content.budgets.button.create"))

        click_button t("default.button.submit")

        expect(page).to have_content("There is a problem")
        expect(page).to have_content(t("activerecord.errors.models.budget.attributes.financial_year.blank"))
        expect(page).to have_content t("activerecord.errors.models.budget.attributes.value.blank")
      end

      scenario "sees validation error when the value is more than allowed" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)

        visit activities_path

        click_on(programme_activity.parent.title)
        click_on t("tabs.activity.children")
        click_on(programme_activity.title)

        click_on(t("page_content.budgets.button.create"))

        select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
        choose("budget[budget_type]", option: "1")
        fill_in "budget[value]", with: "10000000000000.00"
        click_button t("default.button.submit")

        expect(page).to have_content t("activerecord.errors.models.budget.attributes.value.less_than_or_equal_to")
      end
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    let(:fund_activity) { create(:fund_activity) }
    let(:programme_activity) {
      create(:programme_activity,
        parent: fund_activity,
        extending_organisation: user.organisation)
    }
    let!(:project_activity) {
      create(:project_activity,
        parent: programme_activity,
        organisation: user.organisation)
    }

    context "on a programme level activity" do
      scenario "they can view but not create budgets" do
        visit organisation_activity_path(user.organisation, programme_activity)

        expect(page).to have_content(t("page_content.activity.budgets"))
        expect(page).not_to have_content(t("page_content.budgets.button.create"))
      end
    end

    context "on a project level activity" do
      scenario "successfully creates a direct budget by default" do
        _report = create(:report, state: :active, organisation: user.organisation, fund: fund_activity)

        visit activities_path

        click_on(project_activity.title)

        click_on(t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(t("action.budget.create.success"))
      end

      scenario "successfully creates a transferred budget" do
        _report = create(:report, state: :active, organisation: user.organisation, fund: fund_activity)
        another_org = create(:delivery_partner_organisation)

        visit activities_path

        click_on(project_activity.title)

        click_on(t("page_content.budgets.button.create"))

        choose("Transferred")
        choose(another_org.name)
        select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
        fill_in "budget[value]", with: "1000.00"
        click_button t("default.button.submit")

        expect(page).to have_content(t("action.budget.create.success"))
      end

      scenario "successfully creates an external budget" do
        _report = create(:report, state: :active, organisation: user.organisation, fund: fund_activity)

        visit activities_path

        click_on(project_activity.title)

        click_on(t("page_content.budgets.button.create"))

        choose("External Official Development Assistance")
        select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
        fill_in "budget[value]", with: "1000.00"
        click_button t("default.button.submit")

        expect(page).to have_content(t("action.budget.create.success"))
      end

      scenario "for a direct budget it sets the providing org to the service owner (BEIS)" do
        _report = create(:report, state: :active, organisation: user.organisation, fund: fund_activity)

        visit activities_path
        click_on(project_activity.title)
        click_on(t("page_content.budgets.button.create"))

        choose(user.organisation.name)
        select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
        fill_in "budget[value]", with: "1000.00"
        click_button t("default.button.submit")

        expect(page).to have_content(t("action.budget.create.success"))
        expect(project_activity.budgets.last.providing_organisation.service_owner).to eql(true)
        expect(project_activity.budgets.last.providing_organisation_name).to be_nil
      end

      scenario "for a transferred budget it shows an error if the user doesn't select a providing organisation" do
        _report = create(:report, state: :active, organisation: user.organisation, fund: fund_activity)

        visit activities_path
        click_on(project_activity.title)
        click_on(t("page_content.budgets.button.create"))

        choose("Transferred")
        select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
        fill_in "budget[value]", with: "1000.00"
        click_button t("default.button.submit")

        expect(page).to have_content("There is a problem")
        expect(page).to have_content t("activerecord.errors.models.budget.attributes.providing_organisation_id.blank")
      end
    end
  end

  def fill_in_and_submit_budget_form
    choose("Direct (Newton fund)")
    select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
    fill_in "budget[value]", with: "1000.00"
    click_button t("default.button.submit")
  end
end
