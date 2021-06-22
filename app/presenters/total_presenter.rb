class TotalPresenter
  def initialize(bigdecimal)
    @value = ActionController::Base.helpers.number_to_currency(bigdecimal, unit: "£")
  end

  attr_reader :value
end
