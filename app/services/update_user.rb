class UpdateUser
  attr_accessor :user, :organisation, :reset_mfa, :additional_organisations

  def initialize(user:, organisation:, active: true, reset_mfa: false, additional_organisations: [])
    self.user = user
    self.organisation = organisation
    self.reset_mfa = reset_mfa
    self.additional_organisations = additional_organisations
    @active = active
  end

  def call
    result = Result.new(true)

    User.transaction do
      user.organisation = organisation
      user.additional_organisations = additional_organisations

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
