class CreateUser
  attr_accessor :user, :organisation

  def initialize(user:, organisation:)
    self.user = user
    self.organisation = organisation
  end

  def call
    result = Result.new(true)

    user.organisation = organisation
    # This password will never be used: the user must set a new password upon first login
    # but it must fulfill the password_complexity requirements we set in
    # config/initializers/devise_security
    user.password = "Ab3!#{SecureRandom.uuid}"
    result.success = user.save

    SendWelcomeEmail.new(user: user).call if user.persisted?
    result
  end
end
