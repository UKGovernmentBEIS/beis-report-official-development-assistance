class BudgetPresenter < SimpleDelegator
  def budget_type
    return if super.blank?
    I18n.t("page_content.budget.budget_type.#{super}")
  end

  def status
    return if super.blank?
    I18n.t("page_content.budget.status.#{super}")
  end

  def period_start_date
    return if super.blank?
    I18n.l(super)
  end

  def period_end_date
    return if super.blank?
    I18n.l(super)
  end

  def value
    ActionController::Base.helpers.number_to_currency(super, unit: "£")
  end
end
