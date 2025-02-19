require "rails_helper"

RSpec.describe ActivitiesController do
  context "when the user is not logged in" do
    before do
      logout
    end

    it "redirects the user to the root path" do
      activity = create(:programme_activity)
      get :index
      expect(response).to redirect_to(root_path)
      get :show, params: {organisation_id: activity.organisation, id: activity.id}
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    before do
      allow(subject).to receive(:current_user).and_return(user)
    end

    it "does not show fund (level A) activities" do
      fund_activity = create(:fund_activity)

      get :show, params: {organisation_id: user.organisation.id, id: fund_activity.id}

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not allow downloading a programme as XML" do
      programme = create(:programme_activity, extending_organisation: user.organisation)

      get :show, params: {organisation_id: user.organisation.id, id: programme.id, format: :xml}

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not allow downloading a project as XML" do
      project = create(:project_activity, organisation: user.organisation)

      get :show, params: {organisation_id: user.organisation.id, id: project.id, format: :xml}

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not allow downloading a third-party project as XML" do
      third_party_project = create(:third_party_project_activity, organisation: user.organisation)

      get :show, params: {organisation_id: user.organisation.id, id: third_party_project.id, format: :xml}

      expect(response).to have_http_status(:unauthorized)
    end
  end

  shared_examples "fetches activities" do |params|
    let(:scope) { params[:scope] }
    let(:route) { params[:route] }

    let(:fund) { build_stubbed(:fund_activity) }
    let(:programme) { build_stubbed(:programme_activity) }
    let(:project) { build_stubbed(:project_activity) }
    let(:third_party_projects) { build_stubbed_list(:third_party_project_activity, 2) }
    let(:activities) do
      {
        fund => {
          programme => {
            project => third_party_projects
          }
        }
      }
    end

    let(:fetcher) { instance_double(Activity::GroupedActivitiesFetcher, call: activities) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(Activity::GroupedActivitiesFetcher).to receive(:new).and_return(fetcher)
    end

    context "when signed in as a BEIS user" do
      let(:user) { create(:beis_user) }

      it "does not try to fetch activities when the organisation is BEIS" do
        get route, params: {organisation_id: user.organisation.id}

        expect(Activity::GroupedActivitiesFetcher).not_to have_received(:new)
      end

      it "allows fetching of another organisation's activities" do
        organisation = create(:partner_organisation)

        get route, params: {organisation_id: organisation.id}

        expect(Activity::GroupedActivitiesFetcher).to have_received(:new).with(
          user: user,
          organisation: organisation,
          scope: scope
        )
      end
    end

    context "when signed in as a partner organisation user" do
      let(:user) { create(:partner_organisation_user) }

      it "assigns the activities correctly" do
        get route, params: {organisation_id: user.organisation.id}

        expect(assigns(:grouped_activities)).to eq(activities)
      end

      it "fetches the activities for the user's organisation" do
        get route, params: {organisation_id: user.organisation.id}

        expect(Activity::GroupedActivitiesFetcher).to have_received(:new).with(
          user: user,
          organisation: user.organisation,
          scope: scope
        )
      end

      it "fetches the activities for the user's organisation when the organisation ID is that of another organisation" do
        organisation = create(:partner_organisation)

        get route, params: {organisation_id: organisation.id}

        expect(Activity::GroupedActivitiesFetcher).to have_received(:new).with(
          user: user,
          organisation: user.organisation,
          scope: scope
        )
      end
    end
  end

  describe "#index" do
    include_examples "fetches activities", {route: :index, scope: :current}
  end

  describe "#historic" do
    include_examples "fetches activities", {route: :historic, scope: :historic}
  end

  describe "#show" do
    context "when viewing historical events" do
      let(:user) { create(:partner_organisation_user, organisation: organisation) }
      let(:organisation) { create(:partner_organisation) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:prepare_default_activity_trail)
      end

      let(:activity) { build_stubbed(:project_activity, organisation: organisation) }
      let(:grouper) { instance_double(Activity::HistoricalEventsGrouper, call: double) }

      before do
        allow(Activity).to receive(:find).and_return(activity)
        allow(ActivityPresenter).to receive(:new).and_return(activity)
        policy = instance_double(ActivityPolicy, show?: true)
        allow(ActivityPolicy).to receive(:new).and_return(policy)
        allow(Activity::HistoricalEventsGrouper).to receive(:new).and_return(grouper)
      end

      it "asks the HistoricalEventsGrouper to prepare the 'Change history'" do
        get :show, params: {activity_id: "abc123", organisation_id: organisation.id, tab: "historical_events"}

        expect(Activity::HistoricalEventsGrouper)
          .to have_received(:new)
          .with(activity: activity)

        expect(grouper).to have_received(:call)
      end
    end
  end

  context "deleting activities" do
    let(:activity) { create(:programme_activity, title: nil, form_state: "purpose") }
    let(:policy) { instance_double(ActivityPolicy) }
    let(:user) { instance_double(User) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(ActivityPolicy).to receive(:new).and_return(policy)
      allow(user).to receive(:all_organisations).and_return([])
    end

    describe "#confirm_destroy" do
      context "when authorised" do
        it "responds with status 200 OK" do
          allow(policy).to receive(:destroy?).and_return(true)
          allow(user).to receive(:service_owner?).and_return(true)

          get :confirm_destroy, params: {organisation_id: activity.organisation, activity_id: activity.id}

          expect(response).to have_http_status(:ok)
        end
      end

      context "when unauthorised" do
        it "responds with status 401 Unauthorized" do
          allow(policy).to receive(:destroy?).and_return(false)
          allow(user).to receive(:service_owner?).and_return(false)

          get :confirm_destroy, params: {organisation_id: activity.organisation, activity_id: activity.id}

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    describe "#destroy" do
      context "when authorised" do
        it "destroys the activity and redirects to the organisation activities path" do
          allow(policy).to receive(:destroy?).and_return(true)

          delete :destroy, params: {organisation_id: activity.organisation, id: activity.id}

          expect(Activity.find_by(id: activity.id)).to be_nil

          expect(response).to redirect_to(
            organisation_activities_path(
              activity.organisation,
              deleted_activity_roda_identifier: activity.roda_identifier
            )
          )

          expect(response).to have_http_status(:found)
        end
      end

      context "when unauthorised" do
        it "responds with status 401 Unauthorized" do
          allow(policy).to receive(:destroy?).and_return(false)

          delete :destroy, params: {organisation_id: activity.organisation, id: activity.id}

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
