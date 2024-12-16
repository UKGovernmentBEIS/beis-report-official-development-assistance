RSpec.describe "Users can edit a comment" do
  include HideFromBullet

  let(:beis_user) { create(:beis_user) }
  let(:partner_org_user) { create(:partner_organisation_user) }

  let(:project_activity) { create(:project_activity, organisation: partner_org_user.organisation) }
  let!(:project_activity_report) { create(:report, :active, fund: project_activity.associated_fund, organisation: partner_org_user.organisation) }
  let!(:project_activity_comment) { create(:comment, commentable: project_activity, report_id: project_activity_report.id, owner: partner_org_user) }

  let(:programme_activity) { create(:programme_activity) }
  let!(:programme_activity_comment) { create(:comment, commentable: programme_activity, owner: beis_user) }

  context "editing a comment from the activity view" do
    context "when the activity has no title" do
      it "provides the RODA ID of the activity being commented on" do
        authenticate!(user: beis_user)

        programme_activity.update(form_state: "purpose", title: nil)

        visit organisation_activity_comments_path(programme_activity.organisation, programme_activity)
        click_on t("default.link.edit")

        expect(page).to have_content programme_activity.roda_identifier

        logout
      end
    end

    context "when the user is a BEIS user" do
      before { authenticate!(user: beis_user) }
      after { logout }

      context "for a project activity" do
        context "when the report is editable" do
          scenario "the user cannot edit comments" do
            visit organisation_activity_comments_path(project_activity.organisation, project_activity)
            expect(page).not_to have_content t("default.link.edit")
          end
        end

        context "when the report is not editable" do
          let(:project_activity_report) { create(:report, fund: project_activity.associated_fund, organisation: partner_org_user.organisation) }
          scenario "the user cannot edit comments" do
            visit organisation_activity_comments_path(project_activity.organisation, project_activity)
            expect(page).not_to have_content t("default.link.edit")
          end
        end
      end

      context "for a programme activity" do
        scenario "the user can edit a comment" do
          form = CommentForm.edit_from_activity_page(report: nil, comment: programme_activity_comment)

          form.complete(comment: "Amendments have been made")

          expect(page).to have_content t("action.comment.update.success")
          expect(page).to have_content form.comment
        end
      end
    end

    context "when the user is a partner organisation user" do
      before { authenticate!(user: partner_org_user) }
      after { logout }

      context "for a project activity" do
        context "when the report is editable" do
          scenario "the user can edit any comments left by users in the same organisation" do
            form = CommentForm.edit_from_activity_page(report: project_activity_report, comment: project_activity_comment)

            expect(form).to have_report_summary_information
            form.complete(comment: "Amendments have been made")

            expect(page).to have_content t("action.comment.update.success")
            expect(page).to have_content form.comment
          end

          scenario "the user can edit comments on actuals belonging to the same organisation" do
            actual = create(:actual, :with_comment, report: project_activity_report, parent_activity: project_activity)

            skip_bullet do
              visit organisation_activity_comments_path(project_activity_comment.commentable.organisation, project_activity_comment.commentable)
            end

            expect(page).to have_link("Edit", href: edit_activity_actual_path(project_activity, actual))
          end
        end

        context "when the report is not editable" do
          let(:project_activity_report) { create(:report, :approved, fund: project_activity.associated_fund, organisation: partner_org_user.organisation) }
          scenario "the user cannot edit any comments" do
            visit organisation_activity_comments_path(project_activity.organisation, project_activity)
            expect(page).not_to have_content t("default.link.edit")
          end
        end
      end

      context "for a programme activity" do
        scenario "the user cannot create a comment" do
          visit organisation_activity_comments_path(beis_user.organisation, programme_activity)
          expect(page).not_to have_content t("default.link.edit")
        end
      end
    end
  end

  context "when the form is rendered via the edit action" do
    it "includes breadcrumbs" do
      authenticate!(user: beis_user)

      visit organisation_activity_comments_path(programme_activity.organisation, programme_activity)
      click_on t("default.link.edit")

      within ".govuk-breadcrumbs" do
        expect(page).to have_content("Home")
        expect(page).to have_content(programme_activity.parent.title)
        expect(page).to have_content(programme_activity.title)
      end
    end
  end

  context "when the form is rendered via the update action due to the comment body being empty" do
    before do
      authenticate!(user: beis_user)

      visit organisation_activity_comments_path(programme_activity.organisation, programme_activity)
      click_on t("default.link.edit")
      fill_in "comment[body]", with: ""
      click_button t("default.button.submit")
    end

    after { logout }

    it "includes breadcrumbs" do
      within ".govuk-breadcrumbs" do
        expect(page).to have_content("Home")
        expect(page).to have_content(programme_activity.parent.title)
        expect(page).to have_content(programme_activity.title)
      end
    end

    it "displays an error message" do
      expect(page).to have_content(t("activerecord.errors.messages.blank", attribute: "Body"))
    end
  end
end
