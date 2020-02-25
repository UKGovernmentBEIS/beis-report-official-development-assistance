class UpdateTransaction
  attr_accessor :transaction

  def initialize(transaction:)
    self.transaction = transaction
  end

  def call(attributes: {})
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
