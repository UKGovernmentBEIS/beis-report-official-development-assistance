RSpec.describe "Users can create a comment" do
  let(:beis_user) { create(:beis_user) }
  let(:partner_org_user) { create(:partner_organisation_user) }

  let(:project_activity) { create(:project_activity, organisation: partner_org_user.organisation) }
  let!(:project_activity_report) { create(:report, :active, fund: project_activity.associated_fund, organisation: partner_org_user.organisation, financial_year: 2020, financial_quarter: 1) }

  let(:programme_activity) { create(:programme_activity) }

  context "from the report variance tab" do
    context "when the activity has variance" do
      before do
        variance_stub = instance_double(Activity::VarianceFetcher, activities: [project_activity], total: 0)

        allow(Activity::VarianceFetcher).to receive(:new).and_return(variance_stub)
        allow(project_activity).to receive(:variance_for_report_financial_quarter).with(report: project_activity_report).and_return(100)
      end

      context "when the user is a BEIS user" do
        before { authenticate!(user: beis_user) }
        after { logout }

        context "when the report is editable" do
          scenario "the user cannot add a comment" do
            visit report_path(project_activity_report)
            click_on t("tabs.report.variance.heading")
            expect(page).not_to have_content t("table.body.report.add_comment")
          end
        end

        context "when the report is not editable" do
          let(:project_activity_report) { create(:report, fund: project_activity.associated_fund, organisation: partner_org_user.organisation) }
          scenario "the user cannot add a comment" do
            visit report_path(project_activity_report)
            click_on t("tabs.report.variance.heading")
            expect(page).not_to have_content t("table.body.report.add_comment")
          end
        end
      end

      context "when the user is a partner organisation user" do
        before { authenticate!(user: partner_org_user) }
        after { logout }

        context "when the report is editable" do
          context "when there are no comments about this activity" do
            scenario "the user can add a comment" do
              form = CommentForm.create(report: project_activity_report)

              expect(form).to have_report_summary_information
              form.complete(comment: "This activity underspent")

              expect(Comment.all.count).to eq(1)
              expect(Comment.last.body).to eq(form.comment)

              expect(page).to have_content t("action.comment.create.success")

              within ".activity_comments" do
                expect(page).to have_content form.comment
                expect(page).to have_content I18n.l(Date.today)
                expect(page).to have_link "#{project_activity_report.financial_quarter_and_year} #{project_activity_report.description}"
              end
            end
          end
        end

        context "when the report is not editable" do
          let(:project_activity_report) { create(:report, :approved, fund: project_activity.associated_fund, organisation: partner_org_user.organisation) }
          scenario "the user cannot add a comment" do
            visit report_path(project_activity_report)
            click_on t("tabs.report.variance.heading")
            expect(page).not_to have_content t("table.body.report.add_comment")
          end
        end

        context "when the report is editable but does not belong to this user's organisation" do
          let(:project_activity_report) { create(:report, :active, fund: project_activity.associated_fund, organisation: create(:partner_organisation)) }
          scenario "the user cannot add a comment" do
            visit report_path(project_activity_report)
            expect(page).to have_content t("page_title.errors.not_authorised")
          end
        end
      end
    end
  end

  context "from the activity comments tab" do
    context "when the activity has no title" do
      it "provides the RODA ID of the activity being commented on" do
        authenticate!(user: partner_org_user)

        project_activity.update(form_state: "purpose", title: nil)

        visit organisation_activity_comments_path(project_activity.organisation, project_activity)
        click_on t("page_content.comment.add")

        expect(page).to have_content project_activity.roda_identifier

        logout
      end
    end

    context "when the user is a partner organisation user" do
      before { authenticate!(user: partner_org_user) }
      after { logout }

      context "for a project activity" do
        context "when the report is editable" do
          scenario "the user can create a comment" do
            visit organisation_activity_comments_path(project_activity.organisation, project_activity)
            expect(page).to have_css(".govuk-button")
            click_on t("page_content.comment.add")
            fill_in "comment[body]", with: "Amendments have been made"
            click_button t("default.button.submit")
            expect(page).to have_content "Amendments have been made"
            expect(page).to have_content t("action.comment.create.success")
          end
        end

        context "when the report is not editable" do
          let(:project_activity_report) { create(:report, :approved, fund: project_activity.associated_fund, organisation: partner_org_user.organisation) }
          scenario "the user cannot create a comment" do
            visit organisation_activity_comments_path(project_activity.organisation, project_activity)
            expect(page).not_to have_content t("page_content.comment.add")
          end
        end
      end

      context "for a programme activity" do
        scenario "the user cannot create a comment" do
          visit organisation_activity_comments_path(beis_user.organisation, programme_activity)
          expect(page).not_to have_content t("page_content.comment.add")
        end
      end
    end

    context "when the user is a BEIS user" do
      before { authenticate!(user: beis_user) }
      after { logout }

      context "for a project activity" do
        context "when the report is editable" do
          scenario "the user cannot create a comment" do
            visit organisation_activity_comments_path(project_activity.organisation, project_activity)
            expect(page).not_to have_content t("page_content.comment.add")
          end
        end

        context "when the report is not editable" do
          let(:project_activity_report) { create(:report, :approved, fund: project_activity.associated_fund, organisation: partner_org_user.organisation) }
          scenario "the user cannot create a comment" do
            visit organisation_activity_comments_path(project_activity.organisation, project_activity)
            expect(page).not_to have_content t("page_content.comment.add")
          end
        end
      end

      context "for a programme activity" do
        scenario "the user can create a comment" do
          visit organisation_activity_comments_path(beis_user.organisation, programme_activity)
          expect(page).to have_css(".govuk-button")
          click_on t("page_content.comment.add")
          fill_in "comment[body]", with: "Amendments have been made"
          click_button t("default.button.submit")
          expect(page).to have_content "Amendments have been made"
          expect(page).to have_content t("action.comment.create.success")
        end
      end
    end
  end

  context "when the form is rendered via the new action" do
    it "includes breadcrumbs" do
      authenticate!(user: partner_org_user)

      visit organisation_activity_comments_path(project_activity.organisation, project_activity)
      click_on t("default.link.add")

      within ".govuk-breadcrumbs" do
        expect(page).to have_content("Home")
        expect(page).to have_content("Current Reports")
        expect(page).to have_content(t("page_title.report.show", report_fund: project_activity_report.fund.source_fund.name, report_financial_quarter: project_activity_report.financial_quarter_and_year))
      end
    end
  end

  context "when the form is rendered via the create action due to the comment body being empty" do
    before do
      authenticate!(user: partner_org_user)

      visit organisation_activity_comments_path(project_activity.organisation, project_activity)
      click_on t("default.link.add")
      click_button t("default.button.submit")
    end

    after { logout }

    it "includes breadcrumbs" do
      within ".govuk-breadcrumbs" do
        expect(page).to have_content("Home")
        expect(page).to have_content("Current Reports")
        expect(page).to have_content(t("page_title.report.show", report_fund: project_activity_report.fund.source_fund.name, report_financial_quarter: project_activity_report.financial_quarter_and_year))
      end
    end

    it "displays an error message" do
      expect(page).to have_content(t("activerecord.errors.messages.blank", attribute: "Body"))
    end
  end
end
