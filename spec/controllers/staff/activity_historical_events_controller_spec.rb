require "rails_helper"

RSpec.describe Staff::ActivityHistoricalEventsController do
  let(:user) { create(:delivery_partner_user, organisation: organisation) }
  let(:organisation) { create(:delivery_partner_organisation) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
    allow(controller).to receive(:prepare_default_activity_trail)
  end

  describe "#show" do
    let(:activity) { build_stubbed(:project_activity, organisation: organisation) }
    let(:grouper) { instance_double(Activity::HistoricalEventsGrouper, call: double) }

    before do
      allow(Activity).to receive(:find).and_return(activity)
      policy = instance_double(ActivityPolicy, show?: true)
      allow(ActivityPolicy).to receive(:new).and_return(policy)
      allow(Activity::HistoricalEventsGrouper).to receive(:new).and_return(grouper)
    end

    it "asks the HistoricalEventsGrouper to prepare the 'Change history'" do
      get :show, params: {activity_id: "abc123", organisation_id: organisation.id}

      expect(Activity::HistoricalEventsGrouper)
        .to have_received(:new)
        .with(activity: activity)

      expect(grouper).to have_received(:call)
    end
  end
end
