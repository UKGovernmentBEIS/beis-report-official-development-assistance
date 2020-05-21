# frozen_string_literal: true

class PlannedDisbursementXmlPresenter < SimpleDelegator
  include ActionView::Helpers::NumberHelper

  def period_start_date
    return if super.blank?
    I18n.l(super, format: :iati)
  end

  def period_end_date
    return if super.blank?
    I18n.l(super, format: :iati)
  end

  def value
    number_to_currency(super, unit: "", delimiter: "")
  end
end
