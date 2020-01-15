RSpec.feature "Fund managers can create a programme" do
  let(:organisation) { create(:organisation) }
  let!(:fund) { create(:fund, name: "My fund", organisation: organisation) }

  context "when the user is a fund manager" do
    before { authenticate!(user: create(:fund_manager, organisation: organisation)) }

    context "when the user is not logged in" do
      it "redirects the user to the root path" do
        page.set_rack_session(userinfo: nil)
        visit new_fund_programme_path(fund)
        expect(current_path).to eq(root_path)
      end
    end

    scenario "successfully create a programme" do
      visit dashboard_path
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on("My fund")
      click_on "Create programme"
      fill_in "programme[name]", with: "My new programme"
      click_on I18n.t("generic.button.submit")
      expect(page).to have_content "My new programme"
      expect(page).to have_content "My fund"
      expect(page).to have_content organisation.name
    end

    scenario "can go back to the previous page" do
      visit new_fund_programme_path(fund)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_fund_path(organisation, fund))
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisation: organisation)) }

    scenario "shows the 'unauthorised' error message to the user" do
      visit new_fund_programme_path(fund)

      expect(page).to have_content(I18n.t("pundit.default"))
      expect(page).to have_http_status(:unauthorized)
    end
  end
end
