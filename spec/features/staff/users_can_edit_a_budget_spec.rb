RSpec.describe "Users can edit a budget" do
  before { authenticate!(user: user) }

  context "when signed in beis user" do
    let(:user) { create(:beis_user) }

    scenario "a budget can be successfully edited" do
      activity = create(:programme_activity, organisation: user.organisation)
      budget = create(:budget, parent_activity: activity, value: "10")

      visit organisation_activity_path(user.organisation, activity)
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end

      fill_in "budget[value]", with: "20"
      click_on t("default.button.submit")

      expect(page).to have_content(t("action.budget.update.success"))

      within("##{budget.id}") do
        expect(page).to have_content("20.00")
      end
    end
  end

  context "when signed in as delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    scenario "a budget can be successfully edited" do
      activity = create(:project_activity, organisation: user.organisation)
      report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)
      budget = create(:budget, parent_activity: activity, value: "10", report: report)

      visit organisation_activity_path(user.organisation, activity)
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end

      fill_in "budget[value]", with: "20"
      click_on t("default.button.submit")

      expect(page).to have_content(t("action.budget.update.success"))
      within("##{budget.id}") do
        expect(page).to have_content("20.00")
      end
    end

    scenario "budget update is tracked with public_activity" do
      activity = create(:project_activity, organisation: user.organisation)
      report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)
      budget = create(:budget, parent_activity: activity, budget_type: 1, value: "10", report: report)

      PublicActivity.with_tracking do
        visit organisation_activity_path(user.organisation, activity)
        within("##{budget.id}") do
          click_on t("default.link.edit")
        end

        fill_in "budget[value]", with: "20"
        click_on t("default.button.submit")

        budget = Budget.last
        auditable_event = PublicActivity::Activity.find_by(trackable_id: budget.id)
        expect(auditable_event.key).to eq "budget.update"
        expect(auditable_event.owner_id).to eq user.id
      end
    end

    scenario "validation errors work as expected" do
      activity = create(:project_activity, organisation: user.organisation)
      report = create(:report, state: :active, organisation: user.organisation, fund: activity.associated_fund)
      budget = create(:budget, parent_activity: activity, budget_type: "1", value: "10", report: report)

      visit organisation_activity_path(user.organisation, activity)
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end

      fill_in "budget[value]", with: ""

      click_on t("default.button.submit")

      expect(page).to have_content("There is a problem")
      expect(page).to have_content(t("activerecord.errors.models.budget.attributes.value.blank"))
    end
  end
end
