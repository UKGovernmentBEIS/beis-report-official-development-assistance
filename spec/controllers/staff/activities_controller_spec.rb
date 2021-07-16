require "rails_helper"

RSpec.describe Staff::ActivitiesController do
  context "when the user is not logged in" do
    it "redirects the user to the root path" do
      activity = create(:programme_activity)
      get :index
      expect(response).to redirect_to(root_path)
      get :show, params: {organisation_id: activity.organisation, id: activity.id}
      expect(response).to redirect_to(root_path)
    end
  end

  context "when signed in as a delivery partner user" do
    let(:delivery_partner_user) { create(:delivery_partner_user) }

    before do
      allow(subject).to receive(:current_user).and_return(delivery_partner_user)
      allow(subject).to receive(:logged_in_using_omniauth?).and_return(true)
    end

    it "does not show fund (level A) activities" do
      fund_activity = create(:fund_activity)

      get :show, params: {organisation_id: delivery_partner_user.organisation.id, id: fund_activity.id}

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
            project => third_party_projects,
          },
        },
      }
    end

    let(:fetcher) { instance_double(Activity::GroupedActivitiesFetcher, call: activities) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
      allow(Activity::GroupedActivitiesFetcher).to receive(:new).and_return(fetcher)
    end

    context "when signed in as a BEIS user" do
      let(:user) { create(:beis_user) }

      it "does not try to fetch activities when the organisation is beis" do
        get route, params: {organisation_id: user.organisation.id}

        expect(Activity::GroupedActivitiesFetcher).not_to have_received(:new)
      end

      it "allows fetching of another organisation's activites" do
        organisation = create(:delivery_partner_organisation)

        get route, params: {organisation_id: organisation.id}

        expect(Activity::GroupedActivitiesFetcher).to have_received(:new).with(
          user: user,
          organisation: organisation,
          scope: scope
        )
      end
    end

    context "when signed in as a delivery partner" do
      let(:user) { create(:delivery_partner_user) }

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
        organisation = create(:delivery_partner_organisation)

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
end
