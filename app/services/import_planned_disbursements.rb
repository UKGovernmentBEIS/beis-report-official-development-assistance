require "csv"

class ImportPlannedDisbursements
  RODA_ID_KEY = "RODA identifier"
  FORECAST_COLUMN_HEADER = /FC +(\d{4})\/\d{2} +FY +Q([1-4])/

  def initialize(report:)
    @report = report
  end

  def import(forecasts)
    forecasts.each { |row| import_row(row) }
  end

  def import_row(row)
    roda_identifier = row[RODA_ID_KEY]
    activity = Activity.by_roda_identifier(roda_identifier)

    row.each do |key, value|
      match = FORECAST_COLUMN_HEADER.match(key)
      next unless match

      year = match[1].to_i
      quarter = match[2].to_i

      import_forecast(activity, quarter, year, value)
    end
  end

  def import_forecast(activity, quarter, year, value)
    history = PlannedDisbursementHistory.new(activity, quarter, year, report: @report)
    history.set_value(value)
  end
end
