require "csv"

class ImportPlannedDisbursements
  Error = Struct.new(:row, :column, :value, :message) {
    def csv_row
      row + 2
    end
  }

  RODA_ID_KEY = "RODA identifier"
  FORECAST_COLUMN_HEADER = /FC +(\d{4})\/\d{2} +FY +Q([1-4])/

  attr_reader :errors

  def initialize
    @errors = []
  end

  def import(forecasts)
    ActiveRecord::Base.transaction do
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
    history = PlannedDisbursementHistory.new(activity, quarter, year)
    history.set_value(value)
  rescue ConvertFinancialValue::Error
    @errors << Error.new(@current_index, header, value, I18n.t("importer.errors.planned_disbursement.non_numeric_value"))
  end

  def lookup_activity(roda_identifier)
    activity = Activity.by_roda_identifier(roda_identifier)

    unless activity
      @errors << Error.new(@current_index, RODA_ID_KEY, roda_identifier, I18n.t("importer.errors.planned_disbursement.unknown_identifier"))
      return nil
    end

    activity
  end
end
