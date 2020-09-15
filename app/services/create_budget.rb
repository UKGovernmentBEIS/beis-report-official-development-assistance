class CreateBudget
  attr_accessor :activity

  def initialize(activity:)
    self.activity = activity
  end

  def call(attributes: {})
    budget = Budget.new
    budget.parent_activity = activity
    budget.assign_attributes(attributes)
    budget.value = sanitize_monetary_string(value: attributes[:value])

    unless activity.organisation.service_owner?
      budget.report = editable_report_for_activity(activity: activity)
    end

    result = if budget.valid?
      Result.new(budget.save, budget)
    else
      Result.new(false, budget)
    end

    result
  end

  private def editable_report_for_activity(activity:)
    Report.find_by(organisation: activity.organisation, fund: activity.associated_fund, state: Report::EDITABLE_STATES)
  end

  private def sanitize_monetary_string(value:)
    Monetize.parse(value)
  end
end
