RSpec.feature "users can add benefitting countries" do
  context "when the user is signed as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }
    let(:activity) { create(:project_activity, organisation: user.organisation) }
    let!(:report) { create(:report, fund: activity.associated_fund, organisation: user.organisation) }

    scenario "the user can select benefitting countries based on the full list of all countries" do
      all_non_graduated_benefitting_countires = BenefittingCountry.non_graduated

      visit activity_step_path(activity, :benefitting_countries)

      expect(page).to have_content t("form.legend.activity.benefitting_countries")
      expect(page).to have_content("Afghanistan")
      expect(page).to have_content("Zimbabwe")
      expect(page).to have_selector(".country-checkbox", count: all_non_graduated_benefitting_countires.count)

      check "Gambia"
      check "Pakistan"
      check "Egypt"
      click_button t("form.button.activity.submit")

      activity.reload
      expect(activity.benefitting_countries).to match_array(["GM", "PK", "EG"])
    end

    scenario "the user with JavaScript enabled can select whole regions at once", js: true do
      activity.benefitting_countries = nil
      caribbean_region = BenefittingRegion.find_by_code("1031")
      countries_in_region = BenefittingCountry.non_graduated_for_region(caribbean_region)
      country_codes = countries_in_region.map { |country| country.code }

      visit activity_step_path(activity, :benefitting_countries)

      expect(page).to have_content t("form.legend.activity.benefitting_countries")

      check t("page_content.activity.benefitting_region_check_box", region: caribbean_region.name)
      click_button t("form.button.activity.submit")

      activity.reload
      expect(activity.benefitting_countries).to match_array(country_codes)
    end
  end
end
