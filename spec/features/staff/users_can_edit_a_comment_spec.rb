RSpec.describe "Users can edit a comment" do
  let(:beis_user) { create(:beis_user) }
  let(:delivery_partner_user) { create(:delivery_partner_user) }

  let(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }
  let(:actual) { create(:actual, report: report, activity: activity) }
  let(:report) { create(:report, :active, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
  let!(:comment) { create(:comment, commentable: activity, report_id: report.id, owner: delivery_partner_user) }

  context "editing a comment from the activity view" do
    context "when the user is a BEIS user" do
      before { authenticate!(user: beis_user) }

      context "when the report is editable" do
        scenario "the user cannot edit comments" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content "Edit comment"
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot edit comments" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content "Edit comment"
        end
      end
    end

    context "when the user is a Delivery Partner user" do
      before { authenticate!(user: delivery_partner_user) }

      context "when the report is editable" do
        scenario "the user can edit any comments left by users in the same organisation" do
          form = CommentForm.edit_from_activity_page(report: report, comment: comment)

          expect(form).to have_report_summary_information
          form.complete(comment: "Amendments have been made")

          expect(page).to have_content "Comment successfully updated"
          expect(page).to have_content form.comment
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, :approved, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot edit any comments" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content "Edit"
        end
      end
    end
  end
end
