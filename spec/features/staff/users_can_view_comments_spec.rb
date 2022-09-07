RSpec.feature "Users can view comments on an activity page" do
  before do
    authenticate!(user: user)
  end

  context "when the user is a partner organisation user" do
    let(:user) { create(:delivery_partner_user) }

    scenario "they can view all comments associated with an activity" do
      activity = create(:project_activity, organisation: user.organisation)
      report = create(:report, :active, fund: activity.associated_fund, organisation: user.organisation)

      comment = create(:comment, commentable: activity, report: report, owner: user)
      actual = create(:actual, :with_comment, parent_activity: activity, report: report)
      adjustment = create(:adjustment, parent_activity: activity, report: report)
      refund = create(:refund, parent_activity: activity, report: report)

      visit organisation_activity_details_path(user.organisation, activity)
      click_on t("tabs.activity.comments")

      within "#comment_#{comment.id}" do
        expect(page).to have_content comment.body
        expect(page).to have_content report.description
        expect(page).to have_content "Comment"
      end

      within "#comment_#{actual.comment.id}" do
        expect(page).to have_content actual.comment.body
        expect(page).to have_content report.description
        expect(page).to have_content "Actual"
      end

      within "#comment_#{adjustment.comment.id}" do
        expect(page).to have_content adjustment.comment.body
        expect(page).to have_content report.description
        expect(page).to have_content "Adjustment"
      end

      within "#comment_#{refund.comment.id}" do
        expect(page).to have_content refund.comment.body
        expect(page).to have_content report.description
        expect(page).to have_content "Refund"
      end
    end
  end
end
