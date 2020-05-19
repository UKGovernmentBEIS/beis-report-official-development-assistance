class PlannedDisbursementPresenter < SimpleDelegator
  def planned_disbursement_type
    return if super.blank?
    I18n.t("page_content.planned_disbursements.planned_disbursement_type.#{super}")
  end

  def period_start_date
    return if super.blank?
    I18n.l(super)
  end

  def period_end_date
    return if super.blank?
    I18n.l(super)
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
