class UpdateTransaction
  def initialize(transaction:, user:, report:)
    @transaction = transaction
    @user = user
    @report = report
  end

  def call(attributes: {})
    transaction.assign_attributes(attributes)

    convert_and_assign_value(transaction, attributes[:value])
    changes = transaction.changes
    success = transaction.save

    if success
      HistoryRecorder
        .new(user: user)
        .call(
          changes: changes,
          reference: "Update to Transaction",
          activity: transaction.parent_activity,
          trackable: transaction,
          report: report
        )
      Result.new(true, transaction)
    else
      Result.new(false, transaction)
    end
  end

  private

  attr_reader :transaction, :user, :report

  def convert_and_assign_value(transaction, value)
    transaction.value = ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    transaction.errors.add(:value, I18n.t("activerecord.errors.models.transaction.attributes.value.not_a_number"))
  end
end
