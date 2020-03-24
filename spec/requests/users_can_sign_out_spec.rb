require "rails_helper"

RSpec.describe "signing out of Auth0", type: :request do
  scenario "success" do
    allow(ENV).to receive(:[]).with("BULLET_DEBUG").and_return("false")
    allow(ENV).to receive(:[]).with("AUTH0_CLIENT_ID").and_return("123456")
    allow(ENV).to receive(:[]).with("AUTH0_DOMAIN").and_return("test.auth0")
    host! "test.local"
    mock_successful_authentication

    get "/sign_out"

    expect(request).to redirect_to("https://test.auth0/v2/logout?returnTo=http%3A%2F%2Ftest.local%2F&client_id=123456")
  end
end
