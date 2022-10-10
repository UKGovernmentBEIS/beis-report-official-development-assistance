require "rails_helper"

RSpec.describe ImplementingOrganisationsController do
  let(:activity) { create(:project_activity) }
  let!(:report) { create(:report, fund: activity.associated_fund, organisation: activity.organisation) }
  let(:user) { create(:partner_organisation_user, organisation: activity.organisation) }
  let(:active_organisation) { create(:partner_organisation) }
  let(:inactive_organisation) { create(:partner_organisation, :inactive) }

  before do
    authenticate!(user: user)
    allow(controller).to receive(:current_user).and_return(user)
  end

  after { logout }

  describe "#new" do
    render_views

    it "shows the submit input" do
      get :new, params: {activity_id: activity.id}

      expect(response.body).to include(t("default.button.submit"))
    end

    context "when signed in as a BEIS user" do
      let(:user) { create(:beis_user) }

      it "responds with a 401" do
        get :new, params: {activity_id: activity.id}

        expect(response.status).to eq(401)
      end
    end

    context "when the activity has no editable report" do
      it "responds with a 401" do
        report.destroy

        get :new, params: {activity_id: activity.id}

        expect(response.status).to eq(401)
      end
    end
  end

  describe "#create" do
    before do
      allow(OrgParticipation).to receive(:find_or_initialize_by).and_call_original
    end

    it "asks OrgParticipation to find or initialise an instance" do
      post_org_participation

      expect(OrgParticipation).to have_received(:find_or_initialize_by).with(
        activity: activity,
        organisation: active_organisation
      )
    end

    context "when organisation is active" do
      it "redirects to the activity details tab" do
        post_org_participation

        expect(response).to redirect_to(organisation_activity_details_path(activity.organisation, activity))
      end
    end

    context "when organisation is inactive" do
      it "redirects back to the form" do
        post_org_participation(active: false)

        expect(response).to redirect_to(new_activity_implementing_organisation_path(activity))
      end
    end
  end

  describe "#destroy" do
    it "redirects to the activity details tab" do
      delete_org_participation

      expect(response).to redirect_to(organisation_activity_details_path(activity.organisation, activity))
    end

    context "when logged in as another partner organisation user" do
      let(:other_user) { create(:partner_organisation_user) }

      it "responds with a 401" do
        logout
        authenticate!(user: other_user)
        allow(controller).to receive(:current_user).and_return(other_user)

        delete_org_participation

        expect(response.status).to eq(401)
      end
    end
  end

  def post_org_participation(active: true)
    organisation_id = active ? active_organisation.id : inactive_organisation.id

    post :create, params: {
      implementing_organisation: {
        activity_id: activity.id,
        organisation_id: organisation_id
      },
      activity_id: activity.id
    }
  end

  def delete_org_participation
    delete :destroy, params: {
      implementing_organisation: {organisation_id: activity.organisation.id},
      activity_id: activity.id,
      id: activity.organisation.id
    }
  end
end
