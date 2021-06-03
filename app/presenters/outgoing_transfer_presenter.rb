class OutgoingTransferPresenter < SimpleDelegator
  def value
    return if super.blank?
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end

  def financial_quarter_and_year
    return nil if financial_quarter.nil? || financial_year.nil?
    FinancialQuarter.new(financial_year, financial_quarter).to_s
  end
end
