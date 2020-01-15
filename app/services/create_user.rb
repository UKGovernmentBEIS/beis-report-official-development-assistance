class CreateUser
  attr_accessor :user, :organisation

  def initialize(user:, organisation:)
    self.user = user
    self.organisation = organisation
  end

  def call
    result = Result.new(true)

    User.transaction do
      user.organisation = organisation
      user.save
      begin
        CreateUserInAuth0.new(user: user).call
      rescue Auth0::Exception => e
        result.success = false
        Rails.logger.error("Error adding user #{user.email} to Auth0 during CreateUser with #{e.message}.")
        raise ActiveRecord::Rollback
      end
    end

    SendWelcomeEmail.new(user: user).call if user.persisted?
    result
  end
end
