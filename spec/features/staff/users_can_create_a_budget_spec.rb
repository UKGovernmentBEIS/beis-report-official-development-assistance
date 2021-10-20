RSpec.describe "Users can create a budget" do
  before { authenticate!(user: user) }

  context "when signed in as BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund (level A)" do
      scenario "successfully creates a budget" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        create(:programme_activity, parent: fund_activity)

        visit organisation_activity_path(fund_activity.organisation, fund_activity)

        click_on(t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(t("action.budget.create.success"))
      end
    end

    context "when the activity is a programme (level B)" do
      scenario "successfully creates a budget" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)

        visit organisation_activity_path(programme_activity.organisation, programme_activity)

        click_on(t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(t("action.budget.create.success"))
      end

      scenario "sees validation errors for missing attributes" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)

        visit organisation_activity_path(programme_activity.organisation, programme_activity)

        click_on(t("page_content.budgets.button.create"))

        click_button t("default.button.submit")

        expect(page).to have_content("There is a problem")
        expect(page).to have_content(t("activerecord.errors.models.budget.attributes.financial_year.blank"))
        expect(page).to have_content t("activerecord.errors.models.budget.attributes.value.blank")
      end

      scenario "sees validation error when the value is more than allowed" do
        fund_activity = create(:fund_activity, organisation: user.organisation)
        programme_activity = create(:programme_activity, parent: fund_activity, organisation: user.organisation)

        visit organisation_activity_path(programme_activity.organisation, programme_activity)

        click_on(t("page_content.budgets.button.create"))

        select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
        choose("budget[budget_type]", option: "direct")
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

    context "when the activity is a programme (level B)" do
      scenario "they can view but not create budgets" do
        visit organisation_activity_path(programme_activity.organisation, programme_activity)

        expect(page).to have_content(t("page_content.activity.budgets"))
        expect(page).not_to have_content(t("page_content.budgets.button.create"))
      end
    end

    context "when the activity is a project (level C)" do
      scenario "successfully creates a direct budget by default", js: true do
        _report = create(:report, :active, organisation: user.organisation, fund: fund_activity)

        visit organisation_activity_path(project_activity.organisation, project_activity)

        click_on(t("page_content.budgets.button.create"))

        fill_in_and_submit_budget_form

        expect(page).to have_content(t("action.budget.create.success"))
      end

      scenario "successfully creates an external budget", js: true do
        _report = create(:report, :active, organisation: user.organisation, fund: fund_activity)

        visit organisation_activity_path(project_activity.organisation, project_activity)

        click_on(t("page_content.budgets.button.create"))

        choose("Other official development assistance")
        fill_in("Providing organisation name", with: "Any org in the world")
        select("International NGO")
        select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
        fill_in "budget[value]", with: "1000.00"
        click_button t("default.button.submit")

        expect(page).to have_content(t("action.budget.create.success"))
      end

      scenario "for an external budget it shows an error if the user doesn't input a providing organisation name and type", js: true do
        _report = create(:report, :active, organisation: user.organisation, fund: fund_activity)

        visit organisation_activity_path(programme_activity.organisation, project_activity)
        click_on(t("page_content.budgets.button.create"))

        choose("Other official development assistance")
        select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
        fill_in "budget[value]", with: "1000.00"
        click_button t("default.button.submit")

        expect(page).to have_content("There is a problem")
        expect(page).to have_content t("activerecord.errors.models.budget.attributes.providing_organisation_name.blank")
        expect(page).to have_content t("activerecord.errors.models.budget.attributes.providing_organisation_type.blank")
      end

      context "without JavaScript" do
        scenario "for an external budget it shows an error if the user doesn't input a providing organisation name and type" do
          _report = create(:report, :active, organisation: user.organisation, fund: fund_activity)

          visit organisation_activity_path(project_activity.organisation, project_activity)
          click_on(t("page_content.budgets.button.create"))

          choose("Other official development assistance")
          select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
          fill_in "budget[value]", with: "1000.00"
          click_button t("default.button.submit")

          expect(page).to have_content("There is a problem")
          expect(page).to have_content t("activerecord.errors.models.budget.attributes.providing_organisation_name.blank")
          expect(page).to have_content t("activerecord.errors.models.budget.attributes.providing_organisation_type.blank")
        end
      end
    end
  end

  def fill_in_and_submit_budget_form
    # set the `have_checked_field` argument to  `visible: false`
    # because Capybara doesn’t pick up the  radio button when using the JavaScript driver
    expect(page).to have_checked_field("budget[budget_type]", with: "direct", visible: false)
    select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
    fill_in "budget[value]", with: "1000.00"
    click_button t("default.button.submit")
  end
end
