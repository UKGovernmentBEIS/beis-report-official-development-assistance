RSpec.describe UsersController do
  let(:beis_user) { create(:beis_user) }

  before do
    allow(subject).to receive(:current_user).and_return(beis_user)
  end

  describe "#index" do
    it "accepts a parameter of `active` and renders" do
      get :index, params: {user_state: "active"}

      expect(response).to have_http_status(200)
      expect(response).to render_template(:index)
    end

    it "accepts a parameter of `inactive` and renders" do
      get :index, params: {user_state: "inactive"}

      expect(response).to have_http_status(200)
      expect(response).to render_template(:index)
    end
  end

  describe "#show" do
    it "renders a show template" do
      get :show, params: {id: beis_user.id}

      expect(response).to render_template(:show)
    end
  end
end
