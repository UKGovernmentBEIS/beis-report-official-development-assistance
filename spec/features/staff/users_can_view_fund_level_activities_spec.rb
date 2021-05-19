RSpec.feature "Users can view fund level activities" do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      organisation = create(:delivery_partner_organisation)
      visit organisation_path(organisation)
      expect(current_path).to eq(root_path)
    end
  end

  context "when the user belongs to BEIS" do
    let(:user) { create(:beis_user) }
    before { authenticate!(user: user) }

    scenario "can view a fund level activity" do
      fund_activity = create(:fund_activity)
      create(:programme_activity, parent: fund_activity)

      visit activities_path
      click_on fund_activity.title

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

    context "when the activity is partially complete and doesn't have a title" do
      scenario "it to show a meaningful link to the activity" do
        activity = create(:programme_activity, :at_purpose_step, organisation: user.organisation, title: nil)

        visit activities_path

        expect(page).to have_content("Untitled (#{activity.id})")
      end
    end
  end

  context "when the user does NOT belong to BEIS" do
    let(:user) { create(:delivery_partner_user) }
    before { authenticate!(user: user) }

    it "does not allow them to see funds" do
      fund_activity = create(:fund_activity)

      visit organisation_path(user.organisation)

      expect(page).not_to have_content(fund_activity.title)
    end
  end
end
