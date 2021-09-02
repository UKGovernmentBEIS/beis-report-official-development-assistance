# frozen_string_literal: true

class ReportPresenter < SimpleDelegator
  def state
    return if super.blank?
    I18n.t("label.report.state.#{super.downcase}")
  end

  def can_edit_message
    return if state.blank?
    I18n.t("label.report.can_edit.#{to_model.state.downcase}")
  end

  def deadline
    return if super.blank?
    I18n.l(super)
  end

  def email_title
    return nil if financial_quarter_and_year.nil? || fund.nil? || organisation.nil?
    "#{financial_quarter_and_year} #{fund.roda_identifier} #{organisation.beis_organisation_reference}"
  end

  def filename_for_report_download
    filename(purpose: "report")
  end

  def filename_for_activities_template
    filename(purpose: "activities_upload")
  end

  def filename_for_transactions_template
    filename(purpose: "actuals_upload")
  end

  def filename_for_forecasts_template
    filename(purpose: "forecasts_upload")
  end

  def filename_for_all_reports_download
    financial_quarter_and_year + "-All-Reports.csv"
  end

  def summed_actuals
    TotalPresenter.new(super).value
  end

  def summed_refunds
    TotalPresenter.new(super).value
  end

  def summed_forecasts_for_reportable_activities
    TotalPresenter.new(super).value
  end

  private def filename(purpose:)
    [
      financial_quarter_and_year,
      fund.roda_identifier,
      organisation.beis_organisation_reference,
      purpose,
    ].compact.join("-") + ".csv"
  end
end
