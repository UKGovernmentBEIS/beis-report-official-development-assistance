RSpec.feature "Fund managers can edit a fund" do
  let(:organisation) { create(:organisation, name: "UKSA") }
  let(:fund) { create(:fund, title: "old name", organisation: organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit edit_organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before do
      authenticate!(user: build_stubbed(:fund_manager, organisations: [organisation]))
    end
    
    context "when an activity record exists" do
      scenario "successfully editing a fund" do
        fund = create(:fund, organisation: organisation)
        create(:activity, hierarchy: fund)

        visit dashboard_path
        click_on(I18n.t("page_content.dashboard.button.manage_organisations"))

        click_on(organisation.name)
        click_on(fund.title)

        within(".title") do
          click_on(I18n.t("generic.link.edit"))
        end

        fill_in "fund[title]", with: "My New Fund name"
        click_button I18n.t("form.activity.submit")
        expect(page).to have_content I18n.t("page_title.activity_form.show.sector")
      end
    end
  end

  context "when the user is a delivery_partner" do
    before do
      authenticate!(user: build_stubbed(:delivery_partner, organisations: [organisation]))
    end

    scenario "the user cannot edit the fund" do
      visit edit_organisation_fund_path(organisation, fund)
      expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
    end
  end
end
