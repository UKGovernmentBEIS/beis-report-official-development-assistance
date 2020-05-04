RSpec.describe "Users can edit a budget" do
  before { authenticate!(user: user) }

  context "when signed in beis user" do
    let(:user) { create(:beis_user) }

    scenario "a budget can be successfully edited" do
      activity = create(:programme_activity, organisation: user.organisation)
      budget = create(:budget, parent_activity: activity, budget_type: "original", value: "10")

      visit organisation_activity_path(user.organisation, activity)
      within("##{budget.id}") do
        click_on I18n.t("generic.link.edit")
      end

      fill_in "budget[value]", with: "20"
      choose("budget[budget_type]", option: "2")
      click_on I18n.t("generic.button.submit")

      expect(page).to have_content(I18n.t("form.budget.update.success"))
      expect(page).to have_content("20.00")
      expect(page).to have_content("Updated")
    end
  end

  context "when signed in as delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    scenario "a budget can be successfully edited" do
      activity = create(:project_activity, organisation: user.organisation)
      budget = create(:budget, parent_activity: activity, budget_type: "original", value: "10")

      visit organisation_activity_path(user.organisation, activity)
      within("##{budget.id}") do
        click_on I18n.t("generic.link.edit")
      end

      fill_in "budget[value]", with: "20"
      choose("budget[budget_type]", option: "2")
      click_on I18n.t("generic.button.submit")

      expect(page).to have_content(I18n.t("form.budget.update.success"))
      expect(page).to have_content("20.00")
      expect(page).to have_content("Updated")
    end

    scenario "budget update is tracked with public_activity" do
      activity = create(:project_activity, organisation: user.organisation)
      budget = create(:budget, parent_activity: activity, budget_type: "original", value: "10")

      PublicActivity.with_tracking do
        visit organisation_activity_path(user.organisation, activity)
        within("##{budget.id}") do
          click_on I18n.t("generic.link.edit")
        end

        fill_in "budget[value]", with: "20"
        choose("budget[budget_type]", option: "2")
        click_on I18n.t("generic.button.submit")

        budget = Budget.last
        auditable_event = PublicActivity::Activity.find_by(trackable_id: budget.id)
        expect(auditable_event.key).to eq "budget.update"
        expect(auditable_event.owner_id).to eq user.id
      end
    end

    scenario "validation errors work as expected" do
      activity = create(:project_activity, organisation: user.organisation)
      budget = create(:budget, parent_activity: activity, budget_type: "1", value: "10")

      visit organisation_activity_path(user.organisation, activity)
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
