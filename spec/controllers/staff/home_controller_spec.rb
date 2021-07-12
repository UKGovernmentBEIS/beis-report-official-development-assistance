require "rails_helper"

RSpec.describe Staff::HomeController do
  describe "show" do
    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
    end

    context "when signed in as a BEIS user" do
      let(:user) { create(:beis_user) }
      let(:delivery_partners) { create_list(:delivery_partner_organisation, 5) }

      it "fetches the delivery partners" do
        get :show

        expect(assigns(:delivery_partner_organisations)).to match_array(delivery_partners)
      end

      it "renders the service owner view" do
        expect(get(:show)).to render_template(:service_owner)
      end
    end

    context "when signed in as a delivery partner" do
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
      let(:user) { create(:delivery_partner_user) }

      before do
        allow(Activity::GroupedActivitiesFetcher).to receive(:new).and_return(fetcher)
      end

      it "fetches the activities for the user's organisation" do
        get :show

        expect(Activity::GroupedActivitiesFetcher).to have_received(:new).with(
          user: user,
          organisation: user.organisation,
          scope: :current
        )
      end

      it "assigns the activities correctly" do
        get :show

        expect(assigns(:grouped_activities)).to eq(activities)
      end

      it "renders the delivery partner view" do
        expect(get(:show)).to render_template(:delivery_partner)
      end
    end
  end
end
