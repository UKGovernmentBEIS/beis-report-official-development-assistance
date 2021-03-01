# frozen_string_literal: true

class ReportPresenter < SimpleDelegator
  def state
    return if super.blank?
    I18n.t("label.report.state.#{super.downcase}")
  end

  def deadline
    return if super.blank?
    I18n.l(super)
  end

  def financial_quarter_and_year
    return nil if financial_quarter.nil? || financial_year.nil?
    "FQ#{financial_quarter} #{financial_year}-#{financial_year + 1}"
  end
end
