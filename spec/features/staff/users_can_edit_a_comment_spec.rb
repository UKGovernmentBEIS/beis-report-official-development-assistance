RSpec.describe "Users can edit a comment" do
  let(:beis_user) { create(:beis_user) }
  let(:partner_org_user) { create(:partner_organisation_user) }

  let(:activity) { create(:project_activity, organisation: partner_org_user.organisation) }
  let(:report) { create(:report, :active, fund: activity.associated_fund, organisation: partner_org_user.organisation) }
  let!(:comment) { create(:comment, commentable: activity, report_id: report.id, owner: partner_org_user) }

  context "editing a comment from the activity view" do
    context "when the user is a BEIS user" do
      before { authenticate!(user: beis_user) }

      context "when the report is editable" do
        scenario "the user cannot edit comments" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content t("page_content.comment.edit")
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, fund: activity.associated_fund, organisation: partner_org_user.organisation) }
        scenario "the user cannot edit comments" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content t("page_content.comment.edit")
        end
      end
    end

    context "when the user is a partner organisation user" do
      before { authenticate!(user: partner_org_user) }

      context "when the report is editable" do
        scenario "the user can edit any comments left by users in the same organisation" do
          form = CommentForm.edit_from_activity_page(report: report, comment: comment)

          expect(form).to have_report_summary_information
          form.complete(comment: "Amendments have been made")

          expect(page).to have_content t("action.comment.update.success")
          expect(page).to have_content form.comment
        end

        scenario "the user can edit comments on actuals belonging to the same organisation" do
          actual = create(:actual, :with_comment, report: report, parent_activity: activity)

          visit organisation_activity_comments_path(comment.commentable.organisation, comment.commentable)

          expect(page).to have_link("Edit", href: edit_activity_actual_path(activity, actual))
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, :approved, fund: activity.associated_fund, organisation: partner_org_user.organisation) }
        scenario "the user cannot edit any comments" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content t("default.link.edit")
        end
      end
    end
  end
end
