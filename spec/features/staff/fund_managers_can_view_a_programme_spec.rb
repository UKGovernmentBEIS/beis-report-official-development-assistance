RSpec.feature "Fund managers can view a programme" do
  let(:organisation) { create(:organisation, name: "My organisation") }
  let(:fund) { create(:fund, name: "My fund", organisation: organisation) }

  context "when the user is not logged in" do
    scenario "redirects the user to the root path" do
      programme = create(:programme, fund: fund, organisation: organisation)

      page.set_rack_session(userinfo: nil)
      visit fund_programme_path(fund, programme)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: build_stubbed(:fund_manager, organisation: organisation)) }

    scenario "allows the programme to be viewed" do
      programme = create(:programme, fund: fund, organisation: organisation)

      visit dashboard_path
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(fund.name)
      click_on I18n.t("generic.link.show")

      within "h1" do
        expect(page).to have_content(programme.name)
      end

      expect(page).to have_content(organisation.name)
      expect(page).to have_content(fund.name)
    end

    scenario "can go back to the previous page" do
      programme = create(:programme, fund: fund, organisation: organisation)

      visit fund_programme_path(fund, programme)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_fund_path(organisation, fund))
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisation: organisation)) }

    scenario "the programme cannot be viewed" do
      programme = create(:programme, organisation: organisation, fund: fund)

      visit fund_programme_path(fund, programme)

      expect(page).to have_content(I18n.t("pundit.default"))
      expect(page).to have_http_status(:unauthorized)
    end
  end
end
