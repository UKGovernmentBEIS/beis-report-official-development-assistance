RSpec.feature "Fund managers can create a fund" do
  let!(:organisation) { create(:organisation, name: "UKSA") }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit new_organisation_fund_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: create(:fund_manager)) }

    scenario "successfully create a fund" do
      visit dashboard_path
      click_link(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(I18n.t("page_content.organisation.button.create_fund"))

      expect(page).to have_content(I18n.t("page_title.fund.new"))
      fill_in "fund[name]", with: "My Space Fund"
      click_button I18n.t("generic.button.submit")

      expect(page).to have_content I18n.t("form.fund.create.success")
    end

    scenario "presence validation works as expected" do
      visit new_organisation_fund_path(organisation_id: organisation.id)

      expect(page).to have_content(I18n.t("page_title.fund.new"))

      click_button I18n.t("generic.button.submit")
      expect(page).to_not have_content I18n.t("form.fund.create.success")
      expect(page).to have_content "can't be blank"
    end

    scenario "can go back to the previous page" do
      visit new_organisation_fund_path(organisation_id: organisation.id)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_path(organisation.id))
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisation: organisation)) }

    scenario "hides the 'Create fund' button" do
      visit dashboard_path
      click_link I18n.t("page_content.dashboard.button.manage_organisations")
      click_on(organisation.name)

      expect(page).to have_no_content(I18n.t("page_content.organisation.button.create_fund"))
    end

    scenario "shows the 'unauthorised' error message to the user" do
      visit new_organisation_fund_path(organisation)

      expect(page).to have_content(I18n.t("pundit.default"))
      expect(page).to have_http_status(:unauthorized)
    end
  end
end
