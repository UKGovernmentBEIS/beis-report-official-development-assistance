require "./lib/auth0_api"

class UpdateUserInAuth0
  attr_accessor :user

  def initialize(user:)
    self.user = user
  end

  def call
    return unless synchronise?

    auth0_client.update_user(
      user.identifier,
      email: user.email,
      name: user.name
    )
  end

  private

  def auth0_client
    @auth0_client ||= Auth0Api.new.client
  end

  def synchronise?
    user.email_changed? || user.name_changed?
  end
end
