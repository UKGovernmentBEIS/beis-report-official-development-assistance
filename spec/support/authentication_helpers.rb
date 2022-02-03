module AuthenticationHelpers
  include Warden::Test::Helpers

  def mock_successful_authentication(uid: "12345", name: "Alex", email: "alex@example.com")
    # OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new(
    #   provider: "auth0",
    #   uid: uid,
    #   info: {
    #     name: name,
    #     email: email
    #   }
    # )
  end

  def authenticate!(user: build_stubbed(:administrator))
    allow(User).to receive(:find_by)
      .with(identifier: user.identifier)
      .and_return(user)

    login_as(user, scope: :user)
  end
end
