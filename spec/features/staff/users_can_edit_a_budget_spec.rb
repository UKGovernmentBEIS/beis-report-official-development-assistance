RSpec.describe "Users can edit a budget" do
  before { authenticate!(user: user) }

  context "when signed in beis user" do
    let(:user) { create(:beis_user) }
    let!(:activity) { create(:programme_activity, organisation: user.organisation) }
    let!(:budget) { create(:budget, parent_activity: activity, value: "10", financial_year: 2018) }

    before do
      visit organisation_activity_path(user.organisation, activity)
      within("##{budget.id}") do
        click_on t("default.link.edit")
      end
    end

    scenario "a budget can be successfully edited and a history event added" do
      fill_in "budget[value]", with: "20"

      expect {
        click_on t("default.button.submit")
      }.to change { HistoricalEvent.count }.by(1)

      expect(page).to have_content(t("action.budget.update.success"))
      within("##{budget.id}") do
        expect(page).to have_content("20.00")
      end

      historical_event = HistoricalEvent.last

      expect(historical_event.user_id).to eq(user.id)
      expect(historical_event.activity_id).to eq(activity.id)
      expect(historical_event.value_changed).to eq("value")
      expect(historical_event.new_value).to eq(20)
      expect(historical_event.previous_value).to eq(budget.value)
      expect(historical_event.reference).to eq("Change to Budget")
      expect(historical_event.report).to be_nil
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

    scenario "a budget can be successfully edited and a history event added" do
      fill_in "budget[value]", with: "20"

      expect {
        click_on t("default.button.submit")
      }.to change { HistoricalEvent.count }.by(1)

      expect(page).to have_content(t("action.budget.update.success"))
      within("##{budget.id}") do
        expect(page).to have_content("20.00")
      end

      historical_event = HistoricalEvent.last

      expect(historical_event.user_id).to eq(user.id)
      expect(historical_event.activity_id).to eq(activity.id)
      expect(historical_event.value_changed).to eq("value")
      expect(historical_event.new_value).to eq(20)
      expect(historical_event.previous_value).to eq(budget.value)
      expect(historical_event.reference).to eq("Change to Budget")
      expect(historical_event.report).to eq(report)
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
