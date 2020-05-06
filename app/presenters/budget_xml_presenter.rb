# frozen_string_literal: true

class BudgetXmlPresenter < SimpleDelegator
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
end
