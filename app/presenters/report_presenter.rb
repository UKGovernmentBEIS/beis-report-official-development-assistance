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

  def oda_type_summary
    return if is_oda.nil?

    I18n.t("is_oda_summary.#{is_oda}")
  end

  def fund_name_and_oda_type
    return fund.source_fund.name if is_oda.nil?

    is_oda ? "#{fund.source_fund.name} (ODA)" : "#{fund.source_fund.name} (non-ODA)"
  end

  def fund_and_oda_type
    return fund.source_fund.short_name if is_oda.nil?

    is_oda ? "#{fund.source_fund.short_name} (ODA)" : "#{fund.source_fund.short_name} (non-ODA)"
  end

  def approved_at
    return if super.blank?
    I18n.l(super, format: :detailed)
  end

  def uploaded_at
    return nil if export_filename.nil?
    uploaded_time_from_filename = Time.parse(export_filename[-18..-5])

    I18n.l(uploaded_time_from_filename, format: :detailed)
  end

  def email_title
    return nil if financial_quarter_and_year.nil? || fund.nil? || organisation.nil?
    "#{financial_quarter_and_year} #{fund.roda_identifier} #{organisation.beis_organisation_reference}"
  end

  def filename_for_activities_template(is_oda:)
    filename(purpose: "activities_upload", is_oda: is_oda)
  end

  def filename_for_actuals_template
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

  private def filename(purpose:, is_oda: nil)
    oda = case is_oda
    when true
      "ODA"
    when false
      "non-ODA"
    when nil
      nil
    end

    [
      financial_quarter_and_year,
      fund.roda_identifier,
      oda,
      organisation.beis_organisation_reference,
      purpose
    ].compact.join("-") + ".csv"
  end
end
