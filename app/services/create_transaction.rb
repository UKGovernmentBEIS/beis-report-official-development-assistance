class CreateTransaction
  attr_accessor :activity

  def initialize(activity:)
    self.activity = activity
  end

  def call(attributes: {})
    transaction = Transaction.new

    transaction.activity = activity
    transaction.assign_attributes(attributes)
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
end
