class CreateTransaction
  attr_accessor :activity, :report

  def initialize(activity:, report: nil)
    self.activity = activity
    self.report = report || Report.editable_for_activity(activity)
  end

  def call(attributes: {})
    transaction = Transaction.new

    transaction.parent_activity = activity
    transaction.assign_attributes(attributes)
    transaction.value = sanitize_monetary_string(value: attributes[:value])

    unless activity.organisation.service_owner?
      transaction.report = report
    end

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
end
