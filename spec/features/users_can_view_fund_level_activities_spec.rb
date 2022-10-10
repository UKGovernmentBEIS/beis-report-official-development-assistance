RSpec.feature "Users can view fund level activities" do
  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }
    after { logout }

    scenario "can view a fund level activity" do
      fund_activity = create(:fund_activity)
      programme = create(:programme_activity, parent: fund_activity)

      visit organisation_activity_path(programme.extending_organisation, programme)
      click_on "Details"
      within(".activity-details") do
        click_on fund_activity.title
      end

      page_displays_an_activity(activity_presenter: ActivityPresenter.new(fund_activity))
    end

    scenario "can view and create programme level activities" do
      fund_activity = create(:fund_activity, organisation: user.organisation)
      programme_activity = create(:programme_activity)
      fund_activity.child_activities << programme_activity
      activity_presenter = ActivityPresenter.new(programme_activity)

      visit organisation_activity_children_path(fund_activity.organisation, fund_activity)

      expect(page).to have_link activity_presenter.display_title
    end
  end
end
