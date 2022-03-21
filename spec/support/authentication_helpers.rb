module AuthenticationHelpers
  include Warden::Test::Helpers

  def authenticate!(user: build_stubbed(:administrator))
    allow(User).to receive(:find_by)
      .with(identifier: user.identifier)
      .and_return(user)

    login_as(user, scope: :user)
  end
end
