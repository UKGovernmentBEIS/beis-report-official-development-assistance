class UpdateUser
  attr_accessor :user, :organisation, :reset_mfa

  def initialize(user:, organisation:, active: true, reset_mfa: false)
    self.user = user
    self.organisation = organisation
    self.reset_mfa = reset_mfa
    @active = active
  end

  def call
    result = Result.new(true)

    User.transaction do
      user.organisation = organisation

      if reset_mfa
        user.mobile_number = nil
        user.mobile_number_confirmed_at = nil
      end

      user.deactivated_at = @active ? nil : DateTime.now

      user.save
    end

    result
  end
end
