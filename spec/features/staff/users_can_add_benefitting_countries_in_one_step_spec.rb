RSpec.feature "users can add benefitting countries" do
  context "when the user is signed as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }
    let(:activity) { create(:project_activity, organisation: user.organisation) }
    let!(:report) { create(:report, :active, fund: activity.associated_fund, organisation: user.organisation) }

    scenario "the user can select benefitting countries based on the full list of all countries" do
      visit activity_step_path(activity, :benefitting_countries)

      expect(page).to have_content t("form.legend.activity.benefitting_countries")
      expect(page).to have_selector(".region-countries-wrapper .govuk-checkboxes__item", count: 143)
      expect(page).to have_content("Afghanistan")
      expect(page).to have_content("Zimbabwe")
      check "Gambia"
      check "Indonesia"
      check "Yemen"
      click_button t("form.button.activity.submit")

      activity.reload
      expect(activity.benefitting_countries).to match_array(["GM", "ID", "YE"])
    end

    scenario "the user with JavaScript enabled can select whole regions at once", js: true do
      visit activity_step_path(activity, :benefitting_countries)

      expect(page).to have_content t("form.legend.activity.benefitting_countries")
      expect(page).to have_selector(".region-countries-wrapper .govuk-checkboxes__item", count: 143)
      expect(page).to have_selector(".govuk-checkboxes__item.region-checkbox-wrapper", count: 16)
      expect(page).to have_content("Afghanistan")
      expect(page).to have_content("Zimbabwe")

      check "Caribbean, regional"
      click_button t("form.button.activity.submit")

      activity.reload
      expect(activity.benefitting_countries).to match_array(["AG", "CU", "DM", "DO", "GD", "HT", "JM", "MS", "LC", "VC"])
    end
  end
end
