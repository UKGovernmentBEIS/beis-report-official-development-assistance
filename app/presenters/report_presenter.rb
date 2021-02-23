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

  def filename_for_report_download
    filename(purpose: "report")
  end

  def filename_for_activities_template
    filename(purpose: "activities_upload")
  end

  def filename_for_transactions_template
    filename(purpose: "transactions_upload")
  end

  def filename_for_forecasts_template
    filename(purpose: "forecasts_upload")
  end

  def filename_for_all_reports_download
    financial_quarter_and_year + "-All-Reports.csv"
  end

  private def filename(purpose:)
    [
      financial_quarter_and_year,
      fund.roda_identifier_fragment,
      organisation.beis_organisation_reference,
      purpose,
    ].compact.join("-") + ".csv"
  end
end
