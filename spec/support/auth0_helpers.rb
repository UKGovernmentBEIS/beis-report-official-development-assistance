module Auth0Helpers
  def stub_auth0_token_request
    stub_request(:post, "https://testdomain/oauth/token")
      .to_return(status: 200, body: '{"access_token":"TOKEN"}')
  end

  def stub_auth0_create_user_request(email:, auth0_identifier: "auth0|123456789")
    stub_request(:post, "https://testdomain/api/v2/users")
      .with(body: hash_including(connection: "Username-Password-Authentication", email: email))
      .to_return(status: 200, body: "{\"user_id\":\"#{auth0_identifier}\"}")
  end

  def stub_auth0_create_user_request_failure(email:, body: "{\"message\":\"The user already exists.\"}")
    stub_request(:post, "https://testdomain/api/v2/users")
      .with(body: hash_including(connection: "Username-Password-Authentication", email: email))
      .to_return(status: 500, body: body)
  end

  def stub_auth0_post_password_change(auth0_identifier: anything)
    stub_request(:post, "https://testdomain/api/v2/tickets/password-change")
      .with(body: hash_including(user_id: auth0_identifier))
      .to_return(
        status: 200,
        body: "{\"ticket\":\"https://testdomain/lo/reset?ticket=123#\"}"
      )
  end

  def stub_auth0_update_user_request(auth0_identifier:, email:, name:)
    stub_request(:patch, "https://testdomain/api/v2/users/#{auth0_identifier}")
      .with(body: hash_including(email: email, name: name))
      .to_return(status: 200, body: "{\"user_id\":\"#{auth0_identifier}\"}")
  end

  def stub_auth0_update_user_request_failure(auth0_identifier:)
    stub_request(:patch, "https://testdomain/api/v2/users/#{auth0_identifier}")
      .to_return(status: 500, body: "")
  end
end
