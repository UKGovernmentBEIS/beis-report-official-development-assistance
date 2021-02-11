class CreateTransaction
  attr_accessor :activity, :report, :transaction

  def initialize(activity:, report: nil)
    self.activity = activity
    self.report = report || Report.editable_for_activity(activity)
    self.transaction = Transaction.new
  end

  def call(attributes: {})
    transaction.parent_activity = activity
    transaction.assign_attributes(attributes)

    convert_and_assign_value(transaction, attributes[:value])

    transaction.description = default_description if transaction.description.nil?

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

  def default_description
    return nil unless transaction.date.present?

    "#{transaction.financial_quarter_and_year} spend on #{activity.title}"
  end
end
