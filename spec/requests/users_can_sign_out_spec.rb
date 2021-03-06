require "rails_helper"

RSpec.describe "signing out of Auth0", type: :request do
  scenario "success" do
    ClimateControl.modify AUTH0_DOMAIN: "test.auth0", AUTH0_CLIENT_ID: "123456", BULLET_DEBUG: "false" do
      host! "test.local"
      mock_successful_authentication
      get "/sign_out"

      expect(request).to redirect_to("https://test.auth0/v2/logout?returnTo=http%3A%2F%2Ftest.local%2F&client_id=123456")
    end
  end
end
