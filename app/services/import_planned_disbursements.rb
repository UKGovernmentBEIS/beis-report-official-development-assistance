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
      forecasts.each_with_index do |row, index|
        @current_index = index
        import_row(row)
      end
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
    log_error("The forecast for #{header} for activity #{activity.roda_identifier} is not a number.")
  end

  def lookup_activity(roda_identifier)
    activity = Activity.by_roda_identifier(roda_identifier)

    unless activity
      log_error("The RODA identifier '#{roda_identifier}' was not recognised.")
      return nil
    end

    unless Report.for_activity(activity).find_by(id: @report.id)
      log_error("The activity #{activity.roda_identifier} is not related to the report, which belongs to #{report_fund} and #{report_organisation}.")
      return nil
    end

    activity
  end

  def log_error(message)
    message = "Line #{@current_index + 2}: #{message}" if @current_index
    @errors << message
  end

  def log_report_not_latest_error(latest_report)
    message = [
      "The report #{@report.id} (#{report_organisation}, #{quarter @report} for #{report_fund},",
      "#{@report.state}) is not the latest for that organisation and fund.",
      "The latest is #{latest_report.id}, for #{quarter latest_report} (#{latest_report.state}).",
    ]

    log_error(message.join(" "))
  end

  def quarter(report)
    "Q#{report.financial_quarter} #{report.financial_year}"
  end

  def report_fund
    @report.fund.roda_identifier
  end

  def report_organisation
    @report.organisation.name
  end
end
