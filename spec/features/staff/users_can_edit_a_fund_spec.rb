RSpec.feature "Users can edit a fund" do
  before do
    authenticate!(user: user)
  end

  let(:fund) { create(:fund, name: "old name", organisation: organisation) }
  let(:organisation) { create(:organisation, name: "UKSA") }
  let(:user) { create(:administrator, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit edit_organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when no activity record exists" do
    scenario "successfully editing a fund" do
      fund = create(:fund, organisation: organisation)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

      click_on(organisation.name)
      click_on(fund.name)

      within(".fund_name") do
        click_on(I18n.t("generic.link.edit"))
      end

      fill_in "fund[name]", with: "My New Fund name"
      click_button I18n.t("generic.button.submit")
      expect(page).to have_content("My New Fund name")
    end
  end

  context "when an activity record exists" do
    scenario "successfully editing a fund" do
      fund = create(:fund, organisation: organisation)
      create(:activity, hierarchy: fund)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

      click_on(organisation.name)
      click_on(fund.name)

      within(".fund_name") do
        click_on(I18n.t("generic.link.edit"))
      end

      fill_in "fund[name]", with: "My New Fund name"
      click_button I18n.t("generic.button.submit")
      expect(page).to have_content("My New Fund name")
    end
  end
end
