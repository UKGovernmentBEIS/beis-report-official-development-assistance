class UpdateTransaction
  def initialize(actual:, user:, report:)
    @actual = actual
    @user = user
    @report = report
  end

  def call(attributes: {})
    actual.assign_attributes(attributes)

    convert_and_assign_value(actual, attributes[:value])
    changes = actual.changes
    success = actual.save

    if success
      HistoryRecorder
        .new(user: user)
        .call(
          changes: changes,
          reference: "Update to Actual",
          activity: actual.parent_activity,
          trackable: actual,
          report: report
        )
      Result.new(true, actual)
    else
      Result.new(false, actual)
    end
  end

  private

  attr_reader :actual, :user, :report

  def convert_and_assign_value(actual, value)
    actual.value = ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    actual.errors.add(:value, I18n.t("activerecord.errors.models.actual.attributes.value.not_a_number"))
  end
end
