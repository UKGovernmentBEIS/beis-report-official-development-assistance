class CreateUser
  attr_accessor :user, :organisation

  def initialize(user:, organisation:)
    self.user = user
    self.organisation = organisation
  end

  def call
    result = Result.new(true)

    user.organisation = organisation
    user.password = SecureRandom.uuid
    result.success = user.save

    SendWelcomeEmail.new(user: user).call if user.persisted?
    result
  end
end
