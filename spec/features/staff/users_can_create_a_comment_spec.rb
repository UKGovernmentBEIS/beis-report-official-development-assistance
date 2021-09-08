RSpec.describe "Users can create a comment" do
  let(:beis_user) { create(:beis_user) }
  let(:delivery_partner_user) { create(:delivery_partner_user) }

  let(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }
  let(:transaction) { create(:actual, report: report, activity: activity) }
  let(:report) { create(:report, :active, fund: activity.associated_fund, organisation: delivery_partner_user.organisation, financial_year: 2020, financial_quarter: 1) }

  context "when the activity has variance" do
    before do
      variance_stub = instance_double(Activity::VarianceFetcher, activities: [activity], total: 0)

      allow(Activity::VarianceFetcher).to receive(:new).and_return(variance_stub)
      allow(activity).to receive(:variance_for_report_financial_quarter).with(report: report).and_return(100)
    end

    context "when the user is a BEIS user" do
      before { authenticate!(user: beis_user) }

      context "when the report is editable" do
        scenario "the user cannot add a comment" do
          visit report_path(report)
          click_on t("tabs.report.variance")
          expect(page).not_to have_content t("table.body.report.add_comment")
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot add a comment" do
          visit report_path(report)
          click_on t("tabs.report.variance")
          expect(page).not_to have_content t("table.body.report.add_comment")
        end
      end
    end

    context "when the user is a Delivery Partner user" do
      before { authenticate!(user: delivery_partner_user) }

      context "when the report is editable" do
        scenario "the user sees 'Add comment' in the view" do
          visit report_path(report)
          click_on t("tabs.report.variance")
          expect(page).to have_content t("table.body.report.add_comment")
          expect(page).to_not have_content t("table.body.report.edit_comment")
        end

        scenario "the user can add a comment" do
          visit report_path(report)
          click_on t("tabs.report.variance")
          click_on t("table.body.report.add_comment")
          fill_in "comment[comment]", with: "This activity underspent"
          click_button t("default.button.submit")
          expect(Comment.all.count).to eq(1)
          expect(page).to have_content "This activity underspent"
          expect(page).to have_content t("action.comment.create.success")
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, :approved, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot add a comment" do
          visit report_path(report)
          click_on t("tabs.report.variance")
          expect(page).not_to have_content t("table.body.report.add_comment")
        end
      end

      context "when the report is editable but does not belong to this user's organisation" do
        let(:report) { create(:report, :active, fund: activity.associated_fund, organisation: create(:delivery_partner_organisation)) }
        scenario "the user cannot add a comment" do
          visit report_path(report)
          expect(page).to have_content t("not_authorised.default")
        end
      end
    end
  end
end
