RSpec.feature "Users can view an activity" do
  let(:organisation) { create(:organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      fund = create(:fund)

      page.set_rack_session(userinfo: nil)

      visit organisation_fund_path(organisation, fund)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: create(:fund_manager, organisations: [organisation])) }

    scenario "a fund activity can be viewed" do
      fund = create(:fund, organisation: organisation)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(fund.title)
      activity_presenter = ActivityPresenter.new(fund)

      expect(page).to have_content activity_presenter.identifier
      expect(page).to have_content activity_presenter.sector
      expect(page).to have_content activity_presenter.title
      expect(page).to have_content activity_presenter.description
      expect(page).to have_content activity_presenter.planned_start_date
      expect(page).to have_content activity_presenter.planned_end_date
      expect(page).to have_content activity_presenter.recipient_region
      expect(page).to have_content activity_presenter.flow
    end

    scenario "can go back to the previous page" do
      fund = create(:fund, organisation: organisation)

      visit organisation_fund_path(organisation, fund)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(
        organisation_path(organisation)
      )
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisations: [organisation])) }

    scenario "the user cannot view the fund activity" do
      fund = create(:fund, organisation: organisation)

      visit organisation_fund_path(organisation, fund)

      expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
    end
  end
end
