require "csv"
require "set"

class ImportPlannedDisbursements
  Error = Struct.new(:row, :column, :value, :message) {
    def csv_row
      row + 2
    end
  }

  RODA_ID_KEY = "Activity RODA Identifier"
  FORECAST_COLUMN_HEADER = /FC +(\d{4})\/\d{2} +FY +Q([1-4])/

  COLUMN_HEADINGS = [
    "Activity Name",
    "Activity Delivery Partner Identifier",
    RODA_ID_KEY,
  ]

  class Generator
    def column_headings
      COLUMN_HEADINGS
    end

    def csv_row(activity)
      [
        activity.title,
        activity.delivery_partner_identifier,
        activity.roda_identifier,
      ]
    end
  end

  attr_reader :errors

  def initialize(uploader:)
    @uploader = uploader
    @errors = []
    @warned_columns = Set.new
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

      if match
        year = match[1].to_i
        quarter = match[2].to_i
        import_forecast(activity, FinancialQuarter.new(year, quarter), value, header: key)
      elsif !COLUMN_HEADINGS.include?(key) && @warned_columns.add?(key)
        @errors << Error.new(-1, key, "", I18n.t("importer.errors.planned_disbursement.unrecognised_column"))
      end
    end
  end

  def import_forecast(activity, financial_quarter, value, header:)
    history = PlannedDisbursementHistory.new(activity, user: @uploader, **financial_quarter)
    history.set_value(value)
  rescue ConvertFinancialValue::Error
    @errors << Error.new(@current_index, header, value, I18n.t("importer.errors.planned_disbursement.non_numeric_value"))
  rescue Encoding::CompatibilityError
    value.force_encoding(Encoding::UTF_8)
    @errors << Error.new(@current_index, header, value, I18n.t("importer.errors.planned_disbursement.invalid_characters"))
  end

  def lookup_activity(roda_identifier)
    activity = Activity.by_roda_identifier(roda_identifier)
    policy = ActivityPolicy.new(@uploader, activity)

    if activity.nil?
      @errors << Error.new(@current_index, RODA_ID_KEY, roda_identifier, I18n.t("importer.errors.planned_disbursement.unknown_identifier"))
      nil
    elsif !policy.create?
      @errors << Error.new(@current_index, RODA_ID_KEY, roda_identifier, I18n.t("importer.errors.planned_disbursement.unauthorised"))
      nil
    else
      activity
    end
  end
end
