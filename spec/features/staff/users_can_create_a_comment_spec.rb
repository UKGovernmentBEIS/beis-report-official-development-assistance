RSpec.describe "Users can create a comment" do
  let(:beis_user) { create(:beis_user) }
  let(:delivery_partner_user) { create(:delivery_partner_user) }

  let(:activity) { create(:project_activity, organisation: delivery_partner_user.organisation) }
  let(:actual) { create(:actual, report: report, activity: activity) }
  let!(:report) { create(:report, :active, fund: activity.associated_fund, organisation: delivery_partner_user.organisation, financial_year: 2020, financial_quarter: 1) }

  context "from the report variance tab" do
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
            click_on "Variance"
            expect(page).not_to have_content "Add comment"
          end
        end

        context "when the report is not editable" do
          let(:report) { create(:report, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
          scenario "the user cannot add a comment" do
            visit report_path(report)
            click_on "Variance"
            expect(page).not_to have_content "Add comment"
          end
        end
      end

      context "when the user is a Delivery Partner user" do
        before { authenticate!(user: delivery_partner_user) }

        context "when the report is editable" do
          context "when there are no comments about this activity" do
            scenario "the user can add a comment" do
              form = CommentForm.create(report: report)

              expect(form).to have_report_summary_information
              form.complete(comment: "This activity underspent")

              expect(Comment.all.count).to eq(1)
              expect(Comment.last.body).to eq(form.comment)

              expect(page).to have_content "Comment successfully created"

              within ".activity_comments" do
                expect(page).to have_content form.comment
                expect(page).to have_content I18n.l(Date.today)
                expect(page).to have_link "#{report.financial_quarter_and_year} #{report.description}"
              end
            end
          end
        end

        context "when the report is not editable" do
          let(:report) { create(:report, :approved, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
          scenario "the user cannot add a comment" do
            visit report_path(report)
            click_on "Variance"
            expect(page).not_to have_content "Add comment"
          end
        end

        context "when the report is editable but does not belong to this user's organisation" do
          let(:report) { create(:report, :active, fund: activity.associated_fund, organisation: create(:delivery_partner_organisation)) }
          scenario "the user cannot add a comment" do
            visit report_path(report)
            expect(page).to have_content "You have not been authorised to see this page."
          end
        end
      end
    end
  end

  context "from the activity comments tab" do
    context "when the user is a Delivery Partner user" do
      before { authenticate!(user: delivery_partner_user) }

      context "when the report is editable" do
        scenario "the user can create a comment" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).to have_css(".govuk-button")
          click_on "Add a comment"
          fill_in "comment[body]", with: "Amendments have been made"
          click_button "Submit"
          expect(page).to have_content "Amendments have been made"
          expect(page).to have_content "Comment successfully created"
        end
      end

      context "when the report is not editable" do
        let(:report) { create(:report, :approved, fund: activity.associated_fund, organisation: delivery_partner_user.organisation) }
        scenario "the user cannot create a comment" do
          visit organisation_activity_comments_path(activity.organisation, activity)
          expect(page).not_to have_content "Add a comment"
        end
      end
    end
  end
end
