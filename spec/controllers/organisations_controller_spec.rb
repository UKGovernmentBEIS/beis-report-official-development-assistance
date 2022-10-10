require "rails_helper"

RSpec.describe Staff::OrganisationsController do
  context "when the user is not logged in" do
    before do
      logout
    end

    it "redirects the user to the root path" do
      get :index
      expect(response).to redirect_to(root_path)
      get :show, params: {id: double}
      expect(response).to redirect_to(root_path)
    end
  end
end
