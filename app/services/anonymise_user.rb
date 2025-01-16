class AnonymiseUser
  attr_accessor :user

  def initialize(user:)
    self.user = user
  end

  def call
    result = Result.new(true)

    User.transaction do
      user.anonymised_at = DateTime.now
      new_email = "deleted.user.#{user.id}@#{user.email.split("@").last}"
      user.email = new_email
      user.name = "Deleted User #{user.id}"
      user.mobile_number = ""
      result.success = user.save!
    end

    result
  end
end
