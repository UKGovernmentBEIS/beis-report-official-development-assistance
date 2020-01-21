RSpec.feature "Users can view an activity" do
  let(:fund) { create(:fund, organisation: organisation) }
  let(:organisation) { create(:organisation) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      activity = create(:activity, hierarchy: fund)

      page.set_rack_session(userinfo: nil)

      visit fund_activity_path(fund, activity)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user is a fund_manager" do
    before { authenticate!(user: build_stubbed(:fund_manager, organisation: organisation)) }

    scenario "a fund activity can be viewed" do
      activity = create(:activity, hierarchy: fund)

      visit dashboard_path
      click_on(I18n.t("page_content.dashboard.button.manage_organisations"))
      click_on(organisation.name)
      click_on(fund.name)

      activity_presenter = ActivityPresenter.new(activity)

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
      activity = create(:activity, hierarchy: fund)

      visit fund_activity_path(fund, activity)

      click_on I18n.t("generic.link.back")

      expect(page).to have_current_path(
        organisation_fund_path(organisation, fund)
      )
    end
  end

  context "when the user is a delivery_partner" do
    before { authenticate!(user: build_stubbed(:delivery_partner, organisation: organisation)) }

    scenario "the user cannot view the fund activity" do
      visit organisation_fund_path(organisation, fund)

      expect(page).to have_content(I18n.t("page_title.errors.not_authorised"))
    end
  end
end
