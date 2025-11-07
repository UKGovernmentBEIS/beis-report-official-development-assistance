RSpec.describe "Users can create a budget" do
  before { authenticate!(user: user) }
  after { logout }

  shared_examples "creatable budget" do
    before do
      visit organisation_activity_path(activity.organisation, activity)
      click_on(t("page_content.budgets.button.create"))
    end

    scenario "successfully creates a budget" do
      fill_in_and_submit_budget_form

      expect(page).to have_content(t("action.budget.create.success"))
    end

    scenario "successfully creates a budget in the past" do
      expect(page).to have_checked_field("budget[budget_type]", with: "direct", visible: false)
      select "2010-2011", from: "budget[financial_year]"
      fill_in "budget[value]", with: "1000.00"
      click_button t("default.button.submit")

      expect(page).to have_content(t("action.budget.create.success"))
    end

    scenario "sees validation errors for missing attributes" do
      click_button t("default.button.submit")

      expect(page).to have_content("There is a problem")
      expect(page).to have_content(t("activerecord.errors.models.budget.attributes.financial_year.blank"))
      expect(page).to have_content t("activerecord.errors.models.budget.attributes.value.blank")
    end

    scenario "sees validation error when the value is more than allowed" do
      select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
      choose("budget[budget_type]", option: "direct")
      fill_in "budget[value]", with: "10000000000000.00"
      click_button t("default.button.submit")

      expect(page).to have_content t("activerecord.errors.models.budget.attributes.value.less_than_or_equal_to")
    end

    scenario "successfully creates an OODA budget" do
      choose("Other official development assistance")
      fill_in("Providing organisation name", with: "Any org in the world")
      select("International NGO")
      select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
      fill_in "budget[value]", with: "1000.00"
      click_button t("default.button.submit")

      expect(page).to have_content(t("action.budget.create.success"))
    end

    scenario "for an OODA budget it shows an error if the user doesn't input a providing organisation name and type" do
      choose("Other official development assistance")
      select "#{Date.current.year}-#{Date.current.next_year.year}", from: "budget[financial_year]"
      fill_in "budget[value]", with: "1000.00"
      click_button t("default.button.submit")

      expect(page).to have_content("There is a problem")
      expect(page).to have_content t("activerecord.errors.models.budget.attributes.providing_organisation_name.blank")
      expect(page).to have_content t("activerecord.errors.models.budget.attributes.providing_organisation_type.blank")
    end
  end

  shared_examples "non-creatable budget" do
    scenario "they cannot create budgets" do
      visit organisation_activity_path(activity.organisation, activity)

      expect(page).to have_content(t("page_content.activity.budgets.programme"))
      expect(page).not_to have_content(t("page_content.budgets.button.create"))
    end
  end

  context "when signed in as BEIS user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a fund" do
      let(:activity) { create(:fund_activity, organisation: user.organisation) }

      include_examples "creatable budget"
    end

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, organisation: user.organisation) }

      include_examples "creatable budget"
    end

    context "when the activity is a project" do
      let(:programme_activity) { create(:programme_activity, organisation: user.organisation) }
      let(:activity) { create(:project_activity, parent: programme_activity) }

      include_examples "non-creatable budget"
    end
  end

  context "when signed in as a partner organisation user" do
    before do
      create(:report, :active, organisation: user.organisation, fund: activity.associated_fund)
    end

    let(:user) { create(:partner_organisation_user) }

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity, extending_organisation: user.organisation) }

      include_examples "non-creatable budget"
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity, organisation: user.organisation) }

      include_examples "creatable budget"
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
