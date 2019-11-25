class SendWelcomeEmail
  attr_accessor :user

  def initialize(user:)
    self.user = user
  end

  def call
    UserMailer.welcome(user).deliver_later
  end
end
