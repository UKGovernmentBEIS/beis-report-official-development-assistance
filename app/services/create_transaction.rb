class CreateTransaction
  attr_accessor :activity

  def initialize(activity:)
    self.activity = activity
  end

  def call(attributes: {})
    transaction = Transaction.new

    transaction.parent_activity = activity
    transaction.assign_attributes(attributes)
    transaction.submission = submission(activity: activity)
    transaction.value = sanitize_monetary_string(value: attributes[:value])

    result = if transaction.valid?
      Result.new(transaction.save, transaction)
    else
      Result.new(false, transaction)
    end

    result
  end

  private

  def sanitize_monetary_string(value:)
    Monetize.parse(value)
  end

  def submission(activity:)
    organisation = activity.organisation
    fund = activity.associated_fund
    Submission.active.find_by(organisation: organisation, fund: fund)
  end
end
