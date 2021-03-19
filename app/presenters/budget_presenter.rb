class BudgetPresenter < SimpleDelegator
  def iati_type
    return if super.blank?
    Codelist.new(type: "budget_type", source: "iati").hash_of_named_codes.fetch(super)
  end

  def iati_status
    return if super.blank?
    Codelist.new(type: "budget_status", source: "iati").hash_of_named_codes.fetch(super)
  end

  def period_start_date
    return if super.blank?
    I18n.l(super)
  end

  def period_end_date
    return if super.blank?
    I18n.l(super)
  end

  def financial_year
    return if super.blank?
    "FY #{super}"
  end

  def value
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end

  def currency
    return if super.blank?
    I18n.t("generic.default_currency.#{super.downcase}")
  end
end
