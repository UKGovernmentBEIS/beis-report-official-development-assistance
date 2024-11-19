require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:beis_user) { create(:beis_user) }

  before do
    login_as(beis_user)
  end

  it "redirects /users with no parameter to /users/active" do
    expect(get("/users")).to redirect_to("/users/active")
    expect(response).to have_http_status(301)
  end

  after { logout }
end
