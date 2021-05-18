RSpec.describe "Users can edit a comment" do
  let(:beis_user) { create(:beis_user) }
  let(:delivery_partner_user) { create(:delivery_partner_user) }

  let(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }
  let(:transaction) { create(:transaction, report: report, activity: activity) }
  let(:report) { create(:report, :active, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
  let!(:comment) { create(:comment, activity_id: activity.id, report_id: report.id, owner: delivery_partner_user) }

  context "editing a comment from the report view" do
    context "when the user is a BEIS user" do
      before { authenticate!(user: beis_user) }

      context "when the report is editable" do
        scenario "the user cannot edit a comment" do
          visit report_path(report)
          expect(page).not_to have_content t("table.body.report.edit_comment")
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot edit a comment" do
          visit report_path(report)
          expect(page).not_to have_content t("table.body.report.edit_comment")
        end
      end
    end

    context "when the user is a Delivery Partner user" do
      before { authenticate!(user: delivery_partner_user) }

      context "when the report is editable" do
        scenario "the user sees 'Edit comment' in the view" do
          visit report_path(report)
          expect(page).to have_content t("table.body.report.edit_comment")
          expect(page).to_not have_content t("table.body.report.add_comment")
        end

        scenario "the user can edit a comment" do
          visit report_path(report)
          click_on t("table.body.report.edit_comment")
          fill_in "comment[comment]", with: "Amendments have been made"
          click_button t("default.button.submit")
          expect(page).to have_content "Amendments have been made"
          expect(page).to have_content t("action.comment.update.success")
        end

        scenario "comment update is tracked with PublicActivity" do
          PublicActivity.with_tracking do
            visit report_path(report)
            click_on t("table.body.report.edit_comment")
            fill_in "comment[comment]", with: "Amendments have been made"
            click_button t("default.button.submit")

            comment = Comment.last
            auditable_event = PublicActivity::Activity.last
            expect(auditable_event.key).to eq "comment.update"
            expect(auditable_event.owner_id).to eq delivery_partner_user.id
            expect(auditable_event.trackable_id).to eq comment.id
          end
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot edit a comment" do
          visit report_path(report)
          expect(page).not_to have_content t("table.body.report.edit_comment")
        end
      end

      context "when the report is editable but does not belong to this user's organisation" do
        let(:report) { create(:report, :active, fund: activity.associated_fund, organisation: create(:delivery_partner_organisation)) }
        scenario "the user cannot edit a comment" do
          visit report_path(report)
          expect(page).to have_content t("not_authorised.default")
        end
      end
    end
  end

  context "editing a comment from the activity view" do
    context "when the user is a BEIS user" do
      before { authenticate!(user: beis_user) }

      context "when the report is editable" do
        scenario "the user cannot edit a comment" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content t("table.body.report.edit_comment")
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot edit a comment" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content t("table.body.report.edit_comment")
        end
      end
    end

    context "when the user is a Delivery Partner user" do
      before { authenticate!(user: delivery_partner_user) }

      context "when the report is editable" do
        scenario "the user can edit a comment" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          click_on t("table.body.report.edit_comment")
          fill_in "comment[comment]", with: "Amendments have been made"
          click_button t("default.button.submit")
          expect(page).to have_content "Amendments have been made"
          expect(page).to have_content t("action.comment.update.success")
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot edit a comment" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content t("table.body.report.edit_comment")
        end
      end
    end
  end
end
