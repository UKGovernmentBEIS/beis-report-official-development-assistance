require "./lib/auth0_api"

class CreateUserInAuth0
  attr_accessor :user

  def initialize(user:)
    self.user = user
  end

  def call
    auth0_response = auth0_client.create_user(
      user.name,
      email: user.email,
      password: CreateUserInAuth0.temporary_password,
      connection: "Username-Password-Authentication",
    )
    user.update(identifier: auth0_response.fetch("user_id"))
  end

  def self.temporary_password
    "#{SecureRandom.urlsafe_base64}aA1!"
  end

  private

  def auth0_client
    @auth0_client ||= Auth0Api.new.client
  end
end
