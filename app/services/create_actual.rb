class CreateActual
  attr_accessor :activity, :report, :actual

  def initialize(activity:, report: nil)
    self.activity = activity
    self.report = report || Report.editable_for_activity(activity)
    self.actual = Actual.new
  end

  def call(attributes: {})
    actual.parent_activity = activity
    actual.assign_attributes(attributes)

    convert_and_assign_value(actual, attributes[:value])

    actual.description = default_description if actual.description.nil?
    actual.transaction_type = Transaction::DEFAULT_TRANSACTION_TYPE if actual.transaction_type.nil?
    actual.providing_organisation_name = activity.providing_organisation.name
    actual.providing_organisation_type = activity.providing_organisation.organisation_type
    actual.providing_organisation_reference = activity.providing_organisation.iati_reference

    unless activity.organisation.service_owner?
      actual.report = report
    end

    if actual.comment
      actual.comment.report = @report
      actual.comment.commentable = actual
    end

    Result.new(actual.save, actual)
  end

  private

  def convert_and_assign_value(actual, value)
    actual.value = ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    actual.errors.add(:value, I18n.t("activerecord.errors.models.actual.attributes.value.not_a_number"))
  end

  def default_description
    quarter = actual.financial_quarter_and_year
    return nil unless quarter.present?

    "#{quarter} spend on #{activity.title}"
  end
end
