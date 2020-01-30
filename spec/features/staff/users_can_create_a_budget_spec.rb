RSpec.describe "Users can create a budget" do
  let(:organisation) { create(:organisation, name: "UKSA") }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      activity = create(:activity)
      page.set_rack_session(userinfo: nil)
      visit new_activity_budget_path(activity)
      expect(current_path).to eq(root_path)
    end
  end

  context "on a programme" do
    let!(:activity) { create(:activity, organisation: organisation) }

    context "as a fund manager" do
      let(:fund_manager) { create(:fund_manager, organisation: organisation) }

      before { authenticate!(user: fund_manager) }

      scenario "successfully creates a budget" do
        visit organisation_path(organisation)

        click_on(activity.title)

        click_on(I18n.t("page_content.budgets.button.create"))

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

        expect(page).to have_content(I18n.t("form.budget.create.success"))
      end

      scenario "sees validation errors for missing attributes" do
        visit organisation_path(organisation)

        click_on(activity.title)

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

    context "as a delivery partner" do
      let(:delivery_partner) { create(:delivery_partner, organisation: organisation) }

      before { authenticate!(user: delivery_partner) }

      scenario "cannot create a budget on a programme" do
        visit new_activity_budget_path(activity)

        expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
      end
    end
  end
end
