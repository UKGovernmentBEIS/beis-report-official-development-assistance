class EmailValidator < ActiveModel::Validator
  def validate(record)
    return if record.email.blank? || record.email.match?(URI::MailTo::EMAIL_REGEXP)

    record.errors.add(:email, :invalid)
  end
end
