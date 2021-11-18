class Import::ActualHistory
  VALID_HEADERS = {
    roda_identifier: I18n.t("activerecord.attributes.activity.roda_identifier"),
    financial_quarter: I18n.t("activerecord.attributes.default.financial_quarter"),
    financial_year: I18n.t("activerecord.attributes.default.financial_year"),
    value: I18n.t("activerecord.attributes.default.value"),
  }

  attr_reader :errors, :imported

  def initialize(report:, csv:, user:)
    @report = report
    @headers = csv.headers
    @csv = csv
    @user = user
    @imported = []
    @errors = []
  end

  def call
    import_actual_history(@csv)
  end

  alias imported? call

  private

  def import_actual_history(csv)
    unless headers_valid?
      @errors << headers_error
      return false
    end

    ActiveRecord::Base.transaction do
      csv.each.with_index(2) do |row, row_number|
        row_import = RowImport.new(row_number: row_number, row: row, report: @report)

        if row_import.call
          @imported.append(row_import.actual)
        else
          @errors.concat(row_import.errors)
        end
      end

      if @errors.any?
        raise ActiveRecord::Rollback
      end
    end

    return false if @errors.any?
    record_import_history
    true
  end

  def headers_valid?
    @headers == VALID_HEADERS.values
  end

  def headers_error
    Import::RowError.new(
      column: nil,
      row_number: 1,
      value: nil,
      message: "Invalid headers, must be #{VALID_HEADERS.values.to_sentence}"
    )
  end

  def record_import_history
    imported.each do |actual|
      changes = {
        value: [nil, actual.value],
      }
      HistoryRecorder.new(user: @user).call(
        changes: changes,
        reference: "Actual spend imported",
        activity: actual.parent_activity,
        trackable: actual,
        report: @report
      )
    end
  end

  class RowImport
    attr_reader :errors, :actual, :row_number, :row

    def initialize(row_number:, row:, report:)
      @report = report
      @errors = []
      @row = row
      @row_number = row_number
      @actual = nil
    end

    def call
      unless roda_identifier_valid?
        @errors << roda_identifier_error
        return false
      end

      unless report_valid?
        @errors << report_error
        return false
      end

      create_actual
    end

    private

    def create_actual
      actual = Actual.new(
        parent_activity_id: activity.id,
        report_id: @report.id,
        financial_quarter: financial_quarter,
        financial_year: financial_year,
        value: value
      )
      if actual.valid?(:history)
        actual.save(context: :history)
        @actual = actual
        true
      else
        @errors = active_model_to_import_errors_for_row(actual.errors)
        false
      end
    end

    def activity
      @_activity ||= Activity.by_roda_identifier(roda_identifier)
    end

    def financial_quarter
      @row.field("Financial quarter").strip
    end

    def financial_year
      @row.field("Financial year").strip
    end

    def value
      @row.field("Value").strip
    end

    def report_valid?
      @report.fund.source_fund_code == activity.source_fund_code &&
        @report.organisation == activity.organisation
    end

    def report_error
      Import::RowError
        .new(
          column: VALID_HEADERS[:roda_identifier],
          row_number: row_number,
          value: activity.roda_identifier,
          message: "Activity does not match the fund and organisation of this report"
        )
    end

    def roda_identifier
      @row.field("RODA identifier").strip
    end

    def roda_identifier_valid?
      activity.present? ? true : false
    end

    def roda_identifier_error
      Import::RowError.new(
        column: VALID_HEADERS[:roda_identifier],
        row_number: row_number,
        value: roda_identifier,
        message: "No activity with this RODA identifier could be found"
      )
    end

    def active_model_to_import_errors_for_row(errors)
      errors.map do |error|
        Import::RowError.new(
          column: VALID_HEADERS[error.attribute],
          row_number: row_number,
          value: error.options[:value],
          message: error.message
        )
      end
    end
  end
end
