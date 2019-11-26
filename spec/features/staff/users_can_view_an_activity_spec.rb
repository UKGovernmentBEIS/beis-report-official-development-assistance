RSpec.feature "Users can view an activity" do
  before do
    authenticate!(user: user)
  end

  let(:organisation) { create(:organisation) }
  let(:organisation_2) { create(:organisation) }
  let(:viewable_fund) { create(:fund, organisation: organisation) }
  let(:forbidden_fund) { create(:fund, organisation: organisation_2) }
  let(:viewable_activity) do
    create(:activity,
      hierarchy: viewable_fund,
      planned_start_date: Date.today,
      planned_end_date: Date.tomorrow)
  end
  let(:forbidden_activity) { create(:activity, hierarchy: forbidden_fund) }
  let(:user) { create(:user, organisations: [organisation]) }

  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      page.set_rack_session(userinfo: nil)
      visit activity_path(viewable_activity)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the activity belongs to a fund in the user's organisation" do
    scenario "the user can view the activity" do
      visit activity_path(viewable_activity)

      activity_presenter = ActivityPresenter.new(viewable_activity)

      expect(page).to have_content activity_presenter.identifier
      expect(page).to have_content activity_presenter.sector
      expect(page).to have_content activity_presenter.title
      expect(page).to have_content activity_presenter.description
      expect(page).to have_content activity_presenter.planned_start_date
      expect(page).to have_content activity_presenter.planned_end_date
      expect(page).to have_content activity_presenter.recipient_region
      expect(page).to have_content activity_presenter.flow
    end
  end

  context "when the activity belongs to another organisation" do
    scenario "the user cannot view the activity" do
      expect { visit fund_path(forbidden_activity) }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  scenario "can go back to the previous page" do
    visit activity_path(viewable_activity)

    click_on I18n.t("generic.link.back")

    expect(page).to have_current_path(activities_path)
  end
end
