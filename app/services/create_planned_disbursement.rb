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
    planned_disbursement.value = sanitize_monetary_string(value: attributes[:value])

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

  def sanitize_monetary_string(value:)
    Monetize.parse(value)
  end
end
