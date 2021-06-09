class ForecastPresenter < SimpleDelegator
  def value
    return if super.blank?
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end
end
