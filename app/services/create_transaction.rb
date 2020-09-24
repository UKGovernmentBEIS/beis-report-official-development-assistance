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

    convert_and_assign_value(transaction, attributes[:value])

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

  def convert_and_assign_value(transaction, value)
    transaction.value = ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    transaction.errors.add(:value, I18n.t("activerecord.errors.models.transaction.attributes.value.not_a_number"))
  end
end
