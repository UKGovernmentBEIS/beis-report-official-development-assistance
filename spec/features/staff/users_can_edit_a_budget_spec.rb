RSpec.describe "Users can edit a budget" do
  before { authenticate!(user: user) }

  context "when signed in as BEIS user" do
    let(:user) { create(:beis_user) }

    scenario "a budget can be successfully edited" do
      fund_activity = create(:fund_activity, organisation: user.organisation)
      programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)
      budget = create(:budget, activity: programme_activity, budget_type: "original", value: "10")

      visit organisation_activity_path(user.organisation, programme_activity)
      within("##{budget.id}") do
        click_on I18n.t("generic.link.edit")
      end

      fill_in "budget[value]", with: "20"
      choose("budget[budget_type]", option: "updated")
      click_on I18n.t("generic.button.submit")

      expect(page).to have_content(I18n.t("form.budget.update.success"))
      expect(page).to have_content("20.00")
      expect(page).to have_content("Updated")
    end

    scenario "validation errors work as expected" do
      fund_activity = create(:fund_activity, organisation: user.organisation)
      programme_activity = create(:programme_activity, activity: fund_activity, organisation: user.organisation)
      budget = create(:budget, activity: programme_activity, value: "10")

      visit organisation_activity_path(user.organisation, programme_activity)
      within("##{budget.id}") do
        click_on I18n.t("generic.link.edit")
      end

      fill_in "budget[value]", with: ""
      fill_in "budget[period_start_date(3i)]", with: ""
      fill_in "budget[period_start_date(2i)]", with: ""
      fill_in "budget[period_start_date(1i)]", with: ""
      click_on I18n.t("generic.button.submit")

      expect(page).to have_content("There is a problem")
      expect(page).to have_content("can't be blank")
    end
  end
end
