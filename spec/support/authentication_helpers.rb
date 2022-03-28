module AuthenticationHelpers
  include Warden::Test::Helpers

  def authenticate!(user: build_stubbed(:administrator))
    login_as(user, scope: :user)
  end
end
