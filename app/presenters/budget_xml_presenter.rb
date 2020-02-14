# frozen_string_literal: true

class BudgetXmlPresenter < SimpleDelegator
  XML_BUDGET_TYPES = {"original" => 1, "updated" => 2}
  XML_STATUSES = {"indicative" => 1, "committed" => 2}

  def period_start_date
    return if super.blank?
    I18n.l(super, format: :iati)
  end

  def period_end_date
    return if super.blank?
    I18n.l(super, format: :iati)
  end

  def value
    super.to_s
  end

  def budget_type
    return if super.blank?
    XML_BUDGET_TYPES[super]
  end

  def status
    return if super.blank?
    XML_STATUSES[super]
  end
end
