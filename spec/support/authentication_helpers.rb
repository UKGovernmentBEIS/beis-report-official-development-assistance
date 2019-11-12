module AuthenticationHelpers
  def mock_successful_authentication(uid: "12345", name: "Alex", email: "alex@example.com")
    OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new(
      provider: "auth0",
      uid: uid,
      info: {
        name: name,
        email: email,
      }
    )
  end

  def stub_authenticated_session(name: "Alex", email: "alex@example.com")
    page.set_rack_session(userinfo: {uid: "123456789", info: {name: name, email: email}})
  end
end
