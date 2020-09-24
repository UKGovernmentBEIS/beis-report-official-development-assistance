class UpdateBudget
  attr_accessor :budget

  def initialize(budget:)
    self.budget = budget
  end

  def call(attributes: {})
    budget.assign_attributes(attributes)

    convert_and_assign_value(budget, attributes[:value])

    result = if budget.valid?
      Result.new(budget.save, budget)
    else
      Result.new(false, budget)
    end

    result
  end

  private

  def convert_and_assign_value(budget, value)
    budget.value = ConvertFinancialValue.new.convert(value.to_s)
  rescue ConvertFinancialValue::Error
    budget.errors.add(:value, I18n.t("activerecord.errors.models.budget.attributes.value.not_a_number"))
  end
end
