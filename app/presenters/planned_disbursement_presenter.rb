class PlannedDisbursementPresenter < SimpleDelegator
  def planned_disbursement_type
    return if super.blank?
    I18n.t("table.body.planned_disbursement.planned_disbursement_type_options.#{super}")
  end

  def period_start_date
    return if super.blank?
    I18n.l(super)
  end

  def period_end_date
    return if super.blank?
    I18n.l(super)
  end

  def financial_quarter_and_year
    return nil if financial_quarter.nil? || financial_year.nil?
    "Q#{financial_quarter} #{financial_year}-#{financial_year + 1}"
  end

  def currency
    return if super.blank?
    I18n.t("generic.default_currency.#{super.downcase}")
  end

  def value
    return if super.blank?
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end
end
