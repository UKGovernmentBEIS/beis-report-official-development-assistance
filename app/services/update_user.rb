class UpdateUser
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
    end

    result
  end
end
