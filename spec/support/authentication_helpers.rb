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

  def authenticate!(user: create(:user))
    stub_authenticated_session(
      uid: user.identifier,
      name: user.name,
      email: user.email
    )
  end

  def stub_authenticated_session(uid: "123456789", name: "Alex", email: "alex@example.com")
    page.set_rack_session(userinfo: {uid: uid, info: {name: name, email: email}})
  end
end
