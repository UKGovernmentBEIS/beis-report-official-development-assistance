require "csv"

class ImportPlannedDisbursements
  RODA_ID_KEY = "RODA identifier"
  FORECAST_COLUMN_HEADER = /FC +(\d{4})\/\d{2} +FY +Q([1-4])/

  attr_reader :errors

  def initialize(report:)
    @report = report
    @errors = []
  end

  def import(forecasts)
    latest_report = Report
      .where(fund: @report.fund_id, organisation: @report.organisation_id)
      .in_historical_order
      .first

    ActiveRecord::Base.transaction do
      log_report_not_latest_error(latest_report) unless @report == latest_report
      forecasts.each { |row| import_row(row) }
      raise ActiveRecord::Rollback unless @errors.empty?
    end
  end

  private

  def import_row(row)
    roda_identifier = row[RODA_ID_KEY]
    activity = lookup_activity(roda_identifier)
    return unless activity

    row.each do |key, value|
      match = FORECAST_COLUMN_HEADER.match(key)
      next unless match

      year = match[1].to_i
      quarter = match[2].to_i

      import_forecast(activity, quarter, year, value, header: key)
    end
  end

  def import_forecast(activity, quarter, year, value, header:)
    history = PlannedDisbursementHistory.new(activity, quarter, year, report: @report)
    history.set_value(value)
  rescue ConvertFinancialValue::Error
    @errors << "The forecast for #{header} for activity #{activity.roda_identifier} is not a number."
  end

  def lookup_activity(roda_identifier)
    activity = Activity.by_roda_identifier(roda_identifier)
    return activity if activity

    @errors << "The RODA identifier '#{roda_identifier}' was not recognised."
    nil
  end

  def log_report_not_latest_error(latest_report)
    organisation = @report.organisation.name
    fund = @report.fund.roda_identifier

    message = [
      "The report #{@report.id} (#{organisation}, #{quarter @report} for #{fund},",
      "#{@report.state}) is not the latest for that organisation and fund.",
      "The latest is #{latest_report.id}, for #{quarter latest_report} (#{latest_report.state}).",
    ]

    @errors << message.join(" ")
  end

  def quarter(report)
    "Q#{report.financial_quarter} #{report.financial_year}"
  end
end
