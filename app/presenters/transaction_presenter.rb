class TransactionPresenter < SimpleDelegator
  def date
    return if super.blank?
    I18n.l(super)
  end

  def value
    return if super.blank?
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end

  def financial_quarter_and_year
    return nil if date.blank?
    financial_year = FinancialPeriod.year_from_date(to_model.date).to_i
    "Q#{FinancialPeriod.quarter_from_date(to_model.date)} #{financial_year}-#{financial_year + 1}"
  end
end
