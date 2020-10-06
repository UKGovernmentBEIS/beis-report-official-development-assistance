class CreatePlannedDisbursement
  attr_accessor :activity, :report

  def initialize(activity:, report: nil)
    self.activity = activity
    self.report = report || Report.editable_for_activity(activity)
  end

  def call(attributes: {})
    planned_disbursement = PlannedDisbursement.new

    planned_disbursement.parent_activity = activity
    planned_disbursement.assign_attributes(attributes)

    if attributes.key?(:financial_quarter) && attributes.key?(:financial_year)
      planned_disbursement.period_start_date =
        FinancialPeriod.start_date_from_quarter_and_year(attributes.fetch(:financial_quarter), attributes.fetch(:financial_year))
      planned_disbursement.period_end_date =
        FinancialPeriod.end_date_from_quarter_and_year(attributes.fetch(:financial_quarter), attributes.fetch(:financial_year))
    end

    convert_and_assign_value(planned_disbursement, attributes[:value])

    unless activity.organisation.service_owner?
      planned_disbursement.report = report
    end

    result = if planned_disbursement.valid?
      Result.new(planned_disbursement.save, planned_disbursement)
    else
      Result.new(false, planned_disbursement)
    end

    result
  end

  private

  def convert_and_assign_value(planned_disbursement, value)
    planned_disbursement.value = ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    planned_disbursement.errors.add(:value, I18n.t("activerecord.errors.models.planned_disbursement.attributes.value.not_a_number"))
  end
end
