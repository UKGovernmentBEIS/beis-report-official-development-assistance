OmniAuth.config.test_mode = true

RSpec.configure do |config|
  # Teardown mocked SSO
  config.after(:each) do |_example|
    OmniAuth.config.mock_auth[:auth0] = nil
  end
end
