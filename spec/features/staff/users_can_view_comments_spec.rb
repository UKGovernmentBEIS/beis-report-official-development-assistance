RSpec.feature "Users can view comments on an activity page" do
  before do
    authenticate!(user: user)
  end

  context "when the user is a delivery partner" do
    let(:user) { create(:delivery_partner_user) }

    scenario "they can view all comments associated with an activity" do
      activity = create(:project_activity, organisation: user.organisation)
      report = create(:report, :active, fund: activity.associated_fund, organisation: user.organisation)
      comment = create(:comment, commentable: activity, report: report, owner: user)

      visit organisation_activity_details_path(user.organisation, activity)
      click_on t("tabs.activity.comments")
      expect(page).to have_content comment.body
      expect(page).to have_content report.description
    end
  end
end
