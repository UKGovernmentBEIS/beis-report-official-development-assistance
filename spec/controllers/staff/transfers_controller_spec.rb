require "rails_helper"

RSpec.describe Staff::TransfersController do
  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
  end

  let(:transfer) { create(:transfer, source: activity) }

  context "when logged in as a beis user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      describe "#new" do
        before { get :new, params: {activity_id: activity.id} }

        it { should respond_with 200 }
      end

      describe "#edit" do
        before { get :edit, params: {activity_id: activity.id, id: transfer.id} }

        it { should respond_with 200 }
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      describe "#new" do
        before { get :new, params: {activity_id: activity.id} }

        it { should respond_with 401 }
      end

      describe "#edit" do
        before { get :edit, params: {activity_id: activity.id, id: transfer.id} }

        it { should respond_with 401 }
      end
    end
  end

  context "when logged in as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      describe "#new" do
        before { get :new, params: {activity_id: activity.id} }

        it { should respond_with 401 }
      end

      describe "#edit" do
        before { get :edit, params: {activity_id: activity.id, id: transfer.id} }

        it { should respond_with 401 }
      end
    end
  end
end
