require "./lib/auth0_api"

class CreateUser
  attr_accessor :user

  def initialize(user:)
    self.user = user
  end

  def call
    result = Result.new(true)

    User.transaction do
      user.save
      begin
        auth0_response = Auth0Api.new.client.create_user(
          user.name,
          email: user.email,
          email_verified: true,
          password: "#{SecureRandom.urlsafe_base64}aA1!",
          connection: "Username-Password-Authentication",
        )
        user.update(identifier: auth0_response.fetch("user_id"))
      rescue Auth0::Exception => e
        result.success = false
        Rails.logger.error("Error adding user #{user.email} to Auth0 during CreateUser with #{e.message}.")
        raise ActiveRecord::Rollback
      end
    end

    result
  end
end
