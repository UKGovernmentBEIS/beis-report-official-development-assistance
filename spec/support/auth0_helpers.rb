module Auth0Helpers
  def stub_auth0_token_request
    stub_request(:post, "https://testdomain/oauth/token")
      .to_return(status: 200, body: '{"access_token":"TOKEN"}')
  end

  def stub_auth0_create_user_request(email:, auth0_identifier: "auth0|123456789")
    stub_request(:post, "https://testdomain/api/v2/users")
      .with(body: hash_including(email: email))
      .to_return(status: 200, body: "{\"user_id\":\"#{auth0_identifier}\"}")
  end

  def stub_auth0_create_user_request_failure(email:)
    stub_request(:post, "https://testdomain/api/v2/users")
      .with(body: hash_including(email: email))
      .to_return(status: 500, body: "")
  end
end
