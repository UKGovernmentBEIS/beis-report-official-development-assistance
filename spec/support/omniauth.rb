OmniAuth.config.test_mode = true

OmniAuth.config.on_failure = proc { |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
}

RSpec.configure do |config|
  OmniAuth.config.logger = Logger.new("/dev/null")

  # Teardown mocked SSO
  config.after(:each) do |_example|
    OmniAuth.config.mock_auth[:auth0] = nil
  end
end
