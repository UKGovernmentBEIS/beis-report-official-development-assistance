RSpec.feature "Users can view programe level activites" do
  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }

    it "shows the programme level activity" do
      authenticate!(user: user)

      fund_activity = create(:fund_activity, organisation: user.organisation)
      programme_activity = create(:programme_activity,
        organisation: user.organisation,
        activity: fund_activity)

      visit organisation_path(user.organisation)
      click_on fund_activity.title
      click_on programme_activity.title

      page_displays_an_activity(activity_presenter: ActivityPresenter.new(programme_activity))
    end
  end
end
