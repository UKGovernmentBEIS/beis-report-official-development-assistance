RSpec.feature "Fund managers can view a fund" do
  let(:organisation) { create(:organisation) }

  context "when the user is not logged in" do
    scenario "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_fund_path(organisation, create(:fund, organisation: organisation))
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: build_stubbed(:fund_manager, organisation: organisation)) }

    scenario "allows the fund to be viewed" do
      existing_fund = create(:fund, organisation: organisation)

      visit dashboard_path
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)

      click_on(existing_fund.name)
    end

    scenario "can go back to the previous page" do
      visit organisation_fund_path(organisation, create(:fund, organisation: organisation))

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_path(organisation.id))
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisation: organisation)) }

    scenario "the fund cannot be viewed" do
      existing_fund = create(:fund, organisation: organisation)

      visit dashboard_path
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)

      expect(page).not_to have_content(I18n.t("page_content.organisation.funds"))
      expect(page).not_to have_content(existing_fund.name)
    end
  end
end
