RSpec.describe Staff::Uploads::ActualHistoriesController do
  let(:report) { create(:report, organisation: user.organisation) }

  context "as a BEIS partner user" do
    let(:user) { create(:beis_user) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
    end

    describe "#new" do
      it "renders the view" do
        get :new, params: {report_id: report.id}

        expect(response).to render_template(:new)
      end
    end
  end

  context "as a delivery partner user" do
    let(:user) { create(:delivery_partner_user) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:logged_in_using_omniauth?).and_return(true)
    end

    describe "#new" do
      it "returns unauthorized (401)" do
        get :new, params: {report_id: report.id}

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
