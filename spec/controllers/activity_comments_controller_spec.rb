require "rails_helper"

RSpec.describe ActivityCommentsController do
  let(:beis_user) { create(:beis_user) }
  let(:partner_organisation_user) { create(:partner_organisation_user) }

  let(:programme_activity) { create(:programme_activity) }

  let(:project_activity) { create(:project_activity, organisation: partner_organisation_user.organisation) }
  let!(:project_activity_report) { create(:report, :active, fund: project_activity.associated_fund, organisation: partner_organisation_user.organisation) }

  let(:existing_programme_activity_comment) { create(:comment, commentable: programme_activity, owner: beis_user) }
  let(:existing_project_activity_comment) { create(:comment, commentable: project_activity, owner: partner_organisation_user, report: project_activity_report) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  after { logout }

  describe "#new" do
    render_views

    context "when the activity is a programme" do
      context "when signed in as a BEIS user" do
        let(:user) { beis_user }

        it "shows the submit button" do
          get :new, params: {activity_id: programme_activity.id}

          expect(response.body).to include(t("default.button.submit"))
        end
      end

      context "when signed in as a partner organisation user" do
        let(:user) { partner_organisation_user }

        it "responds with a 401" do
          get :new, params: {activity_id: programme_activity.id}

          expect(response.status).to eq(401)
        end
      end
    end

    context "when the activity is a project" do
      context "when signed in as a BEIS user" do
        let(:user) { beis_user }

        it "responds with a 401" do
          get :new, params: {activity_id: project_activity.id, report_id: project_activity_report.id}

          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a partner organisation user whose organisation is the same as the activity's report" do
        let(:user) { partner_organisation_user }

        it "shows the submit button" do
          get :new, params: {activity_id: project_activity.id, report_id: project_activity_report.id}

          expect(response.body).to include(t("default.button.submit"))
        end
      end

      context "when signed in as a partner organisation user whose organisation is different to the activity's report" do
        let(:user) { create(:partner_organisation_user) }

        it "responds with a 401" do
          get :new, params: {activity_id: project_activity.id, report_id: project_activity_report.id}

          expect(response.status).to eq(401)
        end
      end
    end
  end

  describe "#create" do
    context "when the activity is a programme" do
      context "when signed in as a BEIS user" do
        let(:user) { beis_user }

        it "creates the comment and redirects to organisation activity comments path" do
          old_count = Comment.count

          post_comment(activity_id: programme_activity.id, report_id: "")

          expect(Comment.count).to eq(old_count + 1)
          expect(response).to redirect_to(organisation_activity_comments_path(beis_user.organisation, programme_activity))
        end
      end

      context "when signed in as a partner organisation user" do
        let(:user) { partner_organisation_user }

        it "responds with a 401" do
          post_comment(activity_id: programme_activity.id, report_id: "")

          expect(response.status).to eq(401)
        end
      end
    end

    context "when the activity is a project" do
      context "when signed in as a BEIS user" do
        let(:user) { beis_user }

        it "responds with a 401" do
          post_comment(activity_id: project_activity.id, report_id: project_activity_report.id)

          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a partner organisation user whose organisation is the same as the activity's report" do
        let(:user) { partner_organisation_user }

        it "creates the comment and redirects to organisation activity comments path" do
          old_count = Comment.count

          post_comment(activity_id: project_activity.id, report_id: project_activity_report.id)

          expect(Comment.count).to eq(old_count + 1)
          expect(response).to redirect_to(organisation_activity_comments_path(partner_organisation_user.organisation, project_activity))
        end
      end

      context "when signed in as a partner organisation user whose organisation is different to the activity's report" do
        let(:user) { create(:partner_organisation_user) }

        it "responds with a 401" do
          post_comment(activity_id: project_activity.id, report_id: project_activity_report.id)

          expect(response.status).to eq(401)
        end
      end
    end
  end

  describe "#edit" do
    render_views

    context "when the activity is a programme" do
      context "when signed in as a BEIS user" do
        let(:user) { beis_user }

        it "shows the submit button" do
          get :edit, params: {activity_id: programme_activity.id, id: existing_programme_activity_comment.id}

          expect(response.body).to include(t("default.button.submit"))
        end
      end

      context "when signed in as a partner organisation user" do
        let(:user) { partner_organisation_user }

        it "responds with a 401" do
          get :edit, params: {activity_id: programme_activity.id, id: existing_programme_activity_comment.id}

          expect(response.status).to eq(401)
        end
      end
    end

    context "when the activity is a project" do
      context "when signed in as a BEIS user" do
        let(:user) { beis_user }

        it "responds with a 401" do
          get :edit, params: {activity_id: project_activity.id, id: existing_project_activity_comment.id}

          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a partner organisation user whose organisation is the same as the activity's report" do
        let(:user) { partner_organisation_user }

        it "shows the submit button" do
          get :edit, params: {activity_id: project_activity.id, id: existing_project_activity_comment.id}

          expect(response.body).to include(t("default.button.submit"))
        end
      end

      context "when signed in as a partner organisation user whose organisation is different to the activity's report" do
        let(:user) { create(:partner_organisation_user) }

        it "responds with a 401" do
          get :edit, params: {activity_id: project_activity.id, id: existing_project_activity_comment.id}

          expect(response.status).to eq(401)
        end
      end
    end
  end

  describe "#update" do
    context "when the activity is a programme" do
      context "when signed in as a BEIS user" do
        let(:user) { beis_user }

        it "updates the comment and redirects to organisation activity comments path" do
          put_comment(comment_id: existing_programme_activity_comment.id, activity_id: programme_activity.id)

          updated_comment = Comment.find(existing_programme_activity_comment.id)

          expect(updated_comment.body).to eq(updated_comment_body)
          expect(response).to redirect_to(organisation_activity_comments_path(beis_user.organisation, programme_activity))
        end
      end

      context "when signed in as a partner organisation user" do
        let(:user) { partner_organisation_user }

        it "responds with a 401" do
          put_comment(comment_id: existing_programme_activity_comment.id, activity_id: programme_activity.id)

          expect(response.status).to eq(401)
        end
      end
    end

    context "when the activity is a project" do
      context "when signed in as a BEIS user" do
        let(:user) { beis_user }

        it "responds with a 401" do
          put_comment(comment_id: existing_project_activity_comment.id, activity_id: project_activity.id)

          expect(response.status).to eq(401)
        end
      end

      context "when signed in as a partner organisation user whose organisation is the same as the activity's report" do
        let(:user) { partner_organisation_user }

        it "updates the comment and redirects to organisation activity comments path" do
          put_comment(comment_id: existing_project_activity_comment.id, activity_id: project_activity.id)

          updated_comment = Comment.find(existing_project_activity_comment.id)

          expect(updated_comment.body).to eq(updated_comment_body)
          expect(response).to redirect_to(organisation_activity_comments_path(partner_organisation_user.organisation, project_activity))
        end
      end

      context "when signed in as a partner organisation user whose organisation is different to the activity's report" do
        let(:user) { create(:partner_organisation_user) }

        it "responds with a 401" do
          put_comment(comment_id: existing_project_activity_comment.id, activity_id: project_activity.id)

          expect(response.status).to eq(401)
        end
      end
    end
  end

  def post_comment(activity_id:, report_id:)
    post :create, params: {
      activity_id: activity_id,
      comment: {body: "Nihilism slips on a banana peel.", report_id: report_id}
    }
  end

  def put_comment(comment_id:, activity_id:)
    put :update, params: {
      id: comment_id,
      activity_id: activity_id,
      comment: {body: updated_comment_body}
    }
  end

  def updated_comment_body
    "Abstraction set a treehouse on fire."
  end
end
