class CreatePlannedDisbursement
  attr_accessor :activity

  def initialize(activity:)
    self.activity = activity
  end

  def call(attributes: {})
    planned_disbursement = PlannedDisbursement.new

    planned_disbursement.parent_activity = activity
    planned_disbursement.report = report
    planned_disbursement.assign_attributes(attributes)
    planned_disbursement.value = sanitize_monetary_string(value: attributes[:value])

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

  def report
    organisation = activity.organisation
    fund = activity.associated_fund
    Report.active.find_by(organisation: organisation, fund: fund)
  end
end
