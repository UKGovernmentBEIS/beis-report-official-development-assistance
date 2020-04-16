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

    result = if budget.valid?
      Result.new(budget.save, budget)
    else
      Result.new(false, budget)
    end

    result
  end

  private

  def sanitize_monetary_string(value:)
    Monetize.parse(value)
  end
end
