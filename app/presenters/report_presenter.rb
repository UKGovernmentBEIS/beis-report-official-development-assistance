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
end
