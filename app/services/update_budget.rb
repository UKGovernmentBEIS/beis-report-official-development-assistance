class UpdateBudget
  attr_accessor :budget, :user

  def initialize(budget:, user:)
    self.budget = budget
    self.user = user
  end

  def call(attributes: {})
    budget.assign_attributes(attributes)

    convert_and_assign_value(budget, attributes[:value])

    result = if budget.valid?
      result = Result.new(budget.save, budget)
      record_historical_event(attributes) if result.success?
      result
    else
      Result.new(false, budget)
    end

    result
  end

  private

  def record_historical_event(attributes)
    HistoryRecorder.new(user: user).call(
      changes: changes_to_tracked_attributes,
      reference: "Change to Budget",
      activity: budget.parent_activity,
      trackable: budget,
      report: report
    )
  end

  def report
    Report.editable_for_activity(budget.parent_activity)
  end

  def changes_to_tracked_attributes
    [
      :value,
      :budget_type,
      :financial_year,
      :providing_organisation_name,
      :providing_organisation_type,
      :providing_organisation_reference,
    ].filter_map { |attribute|
      [attribute, budget.saved_change_to_attribute(attribute)] if budget.saved_change_to_attribute?(attribute)
    }.to_h
  end

  def convert_and_assign_value(budget, value)
    budget.value = ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    budget.errors.add(:value, I18n.t("activerecord.errors.models.budget.attributes.value.not_a_number"))
  end
end
