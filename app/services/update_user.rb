class UpdateUser
  attr_accessor :user, :organisations

  def initialize(user:, organisations: [])
    self.user = user
    self.organisations = organisations
  end

  def call
    result = Result.new(true)

    User.transaction do
      user.organisations = organisations

      begin
        UpdateUserInAuth0.new(user: user).call
      rescue Auth0::Exception => e
        result.success = false
        Rails.logger.error("Error updating user #{user.email} to Auth0 during UpdateUser with #{e.message}.")
        raise ActiveRecord::Rollback
      end

      user.save
    end

    result
  end
end
