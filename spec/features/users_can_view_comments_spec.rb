RSpec.feature "Users can view comments on an activity page" do
  let(:partner_organisation_user) { create(:partner_organisation_user) }
  let(:beis_user) { create(:beis_user) }

  let(:project_activity) { create(:project_activity, organisation: partner_organisation_user.organisation) }
  let!(:project_activity_report) { create(:report, :active, fund: project_activity.associated_fund, organisation: partner_organisation_user.organisation) }
  let!(:project_activity_comment) { create(:comment, commentable: project_activity, report: project_activity_report, owner: partner_organisation_user) }
  let!(:project_activity_actual) { create(:actual, :with_comment, parent_activity: project_activity, report: project_activity_report) }
  let!(:project_activity_adjustment) { create(:adjustment, parent_activity: project_activity, report: project_activity_report) }
  let!(:project_activity_refund) { create(:refund, parent_activity: project_activity, report: project_activity_report) }

  before do
    authenticate!(user: user)
  end

  after { logout }

  context "when the user is a partner organisation user" do
    let(:user) { partner_organisation_user }

    scenario "they can see all comments associated with one of their organisation's project activities" do
      expect_user_to_see_all_project_activity_comments
    end

    scenario "they can see comments associated with programme activities for which they are the extending organisation" do
      programme_activity = create(:programme_activity, extending_organisation: partner_organisation_user.organisation)
      programme_activity_comment = create(:comment, commentable: programme_activity, report: nil, owner: beis_user)
      visit organisation_activity_details_path(beis_user.organisation, programme_activity)

      click_on t("tabs.activity.comments")

      within "#comment_#{programme_activity_comment.id}" do
        expect(page).to have_content programme_activity_comment.body
        expect(page).to have_content "Comment"
      end
    end
  end

  context "when the user is a BEIS user" do
    let(:user) { beis_user }

    scenario "they can view all comments associated with a project activity" do
      expect_user_to_see_all_project_activity_comments
    end

    scenario "they can view comments associated with a programme activity" do
      programme_activity = create(:programme_activity)
      programme_activity_comment = create(:comment, commentable: programme_activity, report: nil, owner: user)
      visit organisation_activity_details_path(user.organisation, programme_activity)

      click_on t("tabs.activity.comments")

      within "#comment_#{programme_activity_comment.id}" do
        expect(page).to have_content programme_activity_comment.body
        expect(page).to have_content "Comment"
      end
    end
  end

  def expect_user_to_see_all_project_activity_comments
    visit organisation_activity_details_path(partner_organisation_user.organisation, project_activity)
    click_on t("tabs.activity.comments")

    within "#comment_#{project_activity_comment.id}" do
      expect(page).to have_content project_activity_comment.body
      expect(page).to have_content project_activity_report.description
      expect(page).to have_content "Comment"
    end

    within "#comment_#{project_activity_actual.comment.id}" do
      expect(page).to have_content project_activity_actual.comment.body
      expect(page).to have_content project_activity_report.description
      expect(page).to have_content "Actual"
    end

    within "#comment_#{project_activity_adjustment.comment.id}" do
      expect(page).to have_content project_activity_adjustment.comment.body
      expect(page).to have_content project_activity_report.description
      expect(page).to have_content "Adjustment"
    end

    within "#comment_#{project_activity_refund.comment.id}" do
      expect(page).to have_content project_activity_refund.comment.body
      expect(page).to have_content project_activity_report.description
      expect(page).to have_content "Refund"
    end
  end
end
