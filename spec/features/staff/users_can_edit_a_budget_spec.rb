RSpec.describe "Users can edit a budget" do
  before { authenticate!(user: user) }

  context "when signed in beis user" do
    let(:user) { create(:beis_user) }
    let!(:activity) { create(:programme_activity, organisation: user.organisation) }
    let!(:budget) { create(:budget, parent_activity: activity, value: "10") }

    before do
      visit organisation_activity_path(user.organisation, activity)
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end
    end

    scenario "a budget can be successfully edited" do
      fill_in "budget[value]", with: "20"
      click_on t("default.button.submit")

      expect(page).to have_content(t("action.budget.update.success"))

      within("##{budget.id}") do
        expect(page).to have_content("20.00")
      end
    end

    scenario "a budget can be successfully deleted" do
      click_on t("default.button.delete")

      expect(page).to have_content(t("action.budget.destroy.success"))
      expect(page).to_not have_content("10.00")

      expect { budget.reload }.to raise_error { ActiveRecord::RecordNotFound }
    end
  end

  context "when signed in as delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    let(:activity) { create(:project_activity, organisation: user.organisation) }
    let(:report) { create(:report, :active, organisation: user.organisation, fund: activity.associated_fund) }

    let!(:budget) { create(:budget, parent_activity: activity, value: "10", report: report) }

    before do
      visit organisation_activity_path(user.organisation, activity)
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end
    end

    scenario "a budget can be successfully edited" do
      fill_in "budget[value]", with: "20"
      click_on t("default.button.submit")

      expect(page).to have_content(t("action.budget.update.success"))
      within("##{budget.id}") do
        expect(page).to have_content("20.00")
      end
    end

    scenario "a budget can be successfully deleted" do
      click_on t("default.button.delete")

      expect(page).to have_content(t("action.budget.destroy.success"))
      expect(page).to_not have_content("10.00")

      expect { budget.reload }.to raise_error { ActiveRecord::RecordNotFound }
    end

    scenario "validation errors work as expected" do
      fill_in "budget[value]", with: ""

      click_on t("default.button.submit")

      expect(page).to have_content("There is a problem")
      expect(page).to have_content(t("activerecord.errors.models.budget.attributes.value.blank"))
    end
  end
end
