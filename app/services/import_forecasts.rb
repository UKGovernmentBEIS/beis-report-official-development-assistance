require "csv"
require "set"

class ImportForecasts
  Error = Struct.new(:row, :column, :value, :message) {
    def csv_row
      row + 2
    end
  }

  RODA_ID_KEY = "Activity RODA Identifier"
  FORECAST_COLUMN_HEADER = /FC +(\d{4})\/\d{2} +FY +Q([1-4])/
  FORECAST_QUARTERS = 20

  COLUMN_HEADINGS = [
    "Activity Name",
    "Activity Partner Organisation Identifier",
    RODA_ID_KEY
  ]

  class Generator
    def initialize(report)
      @report = report
    end

    def column_headings
      reportable_quarters = @report.own_financial_quarter.following(FORECAST_QUARTERS)

      quarter_headers = reportable_quarters.map { |quarter|
        year = quarter.financial_year.start_year
        "FC #{year}/#{(year + 1) % 100} FY Q#{quarter.quarter}"
      }

      COLUMN_HEADINGS + quarter_headers
    end

    def csv_row(activity)
      forecast_values = Array.new(FORECAST_QUARTERS, "")

      [
        activity.title,
        activity.delivery_partner_identifier,
        activity.roda_identifier
      ] + forecast_values
    end
  end

  attr_reader :errors, :imported_forecasts

  def initialize(uploader: nil, report: nil)
    if uploader && report
      raise ArgumentError, "Importing forecasts for arbitrary users and reports is forbidden"
    end

    @uploader = uploader
    @report = report
    @errors = []
    @warned_columns = Set.new
    @imported_forecasts = []
  end

  def import(forecasts)
    latest_report = find_latest_report_in_selected_series

    ActiveRecord::Base.transaction do
      log_report_not_latest_error(latest_report) unless [nil, @report].include?(latest_report)

      forecasts.each_with_index do |row, index|
        @current_index = index
        import_row(row)
      end

      raise ActiveRecord::Rollback unless @errors.empty?
    end
  end

  private

  def find_latest_report_in_selected_series
    return nil unless @report

    Report
      .where(fund: @report.fund_id, organisation: @report.organisation_id)
      .in_historical_order
      .first
  end

  def import_row(row)
    roda_identifier = row[RODA_ID_KEY]
    activity = lookup_activity(roda_identifier)
    return unless activity

    row.each do |key, value|
      match = FORECAST_COLUMN_HEADER.match(key)

      if match
        year = match[1].to_i
        quarter = match[2].to_i
        imported_forecasts << import_forecast(activity, FinancialQuarter.new(year, quarter), value, header: key)
      elsif !COLUMN_HEADINGS.include?(key) && @warned_columns.add?(key)
        @errors << Error.new(-1, key, "", I18n.t("importer.errors.forecast.unrecognised_column"))
      end
    end
  end

  def import_forecast(activity, financial_quarter, value, header:)
    return if value.blank?
    history = ForecastHistory.new(activity, user: @uploader, report: @report, **financial_quarter)
    history.set_value(value)
  rescue ConvertFinancialValue::Error
    @errors << Error.new(@current_index, header, value, I18n.t("importer.errors.forecast.non_numeric_value"))
  rescue Encoding::CompatibilityError
    value.force_encoding(Encoding::UTF_8)
    @errors << Error.new(@current_index, header, value, I18n.t("importer.errors.forecast.invalid_characters"))
  rescue ForecastHistory::SequenceError
    @errors << Error.new(@current_index, header, header, I18n.t("importer.errors.forecast.in_the_past"))
  end

  def lookup_activity(roda_identifier)
    activity = Activity.by_roda_identifier(roda_identifier)

    if activity.nil?
      @errors << Error.new(@current_index, RODA_ID_KEY, roda_identifier, I18n.t("importer.errors.forecast.unknown_identifier"))
      nil
    elsif unauthorized_upload?(activity)
      @errors << Error.new(@current_index, RODA_ID_KEY, roda_identifier, I18n.t("importer.errors.forecast.unauthorised"))
      nil
    elsif activity_unrelated_to_report?(activity)
      @errors << Error.new(@current_index, RODA_ID_KEY, roda_identifier, "The activity is not related to the report, which belongs to #{report_fund} and #{report_organisation}.")
      nil
    else
      activity
    end
  end

  def unauthorized_upload?(activity)
    return false unless @uploader

    policy = ActivityPolicy.new(@uploader, activity)
    !policy.create?
  end

  def activity_unrelated_to_report?(activity)
    return false unless @report
    !Report.for_activity(activity).where(id: @report.id).exists?
  end

  def log_report_not_latest_error(latest_report)
    message = [
      "The report #{@report.id} (#{report_organisation}, #{quarter @report} for #{report_fund},",
      "#{@report.state}) is not the latest for that organisation and fund.",
      "The latest is #{latest_report.id}, for #{quarter latest_report} (#{latest_report.state})."
    ]

    @errors << Error.new(nil, nil, nil, message.join(" "))
  end

  def quarter(report)
    quarter = report.own_financial_quarter
    quarter ? quarter.to_s : "Historic Report"
  end

  def report_fund
    @report.fund.roda_identifier
  end

  def report_organisation
    @report.organisation.name
  end
end
