RSpec.feature "Fund managers can view funds on an organisation page" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  let(:organisation) { create(:organisation) }

  context "when the user is a fund_manager" do
    before do
      authenticate!(user: create(:fund_manager))
    end

    scenario "the user will see them on the organisation show page" do
      fund = create(:fund, organisation: organisation)
      visit organisations_path
      click_link organisation.name

      expect(page).to have_content(I18n.t("page_content.organisation.funds"))
      expect(page).to have_content fund.name
    end

    scenario "can go back to the previous page" do
      fund = create(:fund, organisation: organisation)
      visit organisation_fund_path(organisation, fund)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(organisation_path(organisation))
    end
  end

  context "when the user is a delivery_partner" do
    before do
      authenticate!(user: create(:delivery_partner, organisation: organisation))
    end

    scenario "the user will not see them on the show page for their organisation" do
      fund = create(:fund, organisation: organisation)

      visit organisations_path
      click_link organisation.name

      expect(page).not_to have_content(I18n.t("page_content.organisation.funds"))
      expect(page).not_to have_content fund.name
    end
  end
end
