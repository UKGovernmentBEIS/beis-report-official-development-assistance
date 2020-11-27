class PlannedDisbursementPresenter < SimpleDelegator
  def financial_quarter_and_year
    return nil if financial_quarter.nil? || financial_year.nil?
    "Q#{financial_quarter} #{financial_year}-#{financial_year + 1}"
  end

  def value
    return if super.blank?
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end
end
