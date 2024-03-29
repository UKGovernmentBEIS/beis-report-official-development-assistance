RSpec.shared_examples "a transfer controller" do
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  subject { response }

  context "when logged in as a beis user" do
    let(:user) { create(:beis_user) }

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      describe "#new" do
        before { get :new, params: {activity_id: activity.id} }

        it { should have_http_status(:ok) }
      end

      describe "#edit" do
        before { get :edit, params: {activity_id: activity.id, id: transfer.id} }

        it { should have_http_status(:ok) }
      end
    end

    context "when the activity is a project" do
      let(:activity) { create(:project_activity) }

      describe "#new" do
        before { get :new, params: {activity_id: activity.id} }

        it { should have_http_status(:unauthorized) }
      end

      describe "#edit" do
        before { get :edit, params: {activity_id: activity.id, id: transfer.id} }

        it { should have_http_status(:unauthorized) }
      end
    end
  end

  context "when logged in as a partner organisation user" do
    let(:user) { create(:partner_organisation_user) }

    context "when the activity is a programme" do
      let(:activity) { create(:programme_activity) }

      describe "#new" do
        before { get :new, params: {activity_id: activity.id} }

        it { should have_http_status(:unauthorized) }
      end

      describe "#edit" do
        before { get :edit, params: {activity_id: activity.id, id: transfer.id} }

        it { should have_http_status(:unauthorized) }
      end
    end
  end
end
