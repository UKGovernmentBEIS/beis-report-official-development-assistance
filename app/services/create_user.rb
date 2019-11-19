class CreateUser
  attr_accessor :user, :organisations

  def initialize(user:, organisations: [])
    self.user = user
    self.organisations = organisations
  end

  def call
    result = Result.new(true)

    User.transaction do
      user.organisations = organisations
      user.save
      begin
        CreateUserInAuth0.new(user: user).call
      rescue Auth0::Exception => e
        result.success = false
        Rails.logger.error("Error adding user #{user.email} to Auth0 during CreateUser with #{e.message}.")
        raise ActiveRecord::Rollback
      end
    end

    result
  end
end
