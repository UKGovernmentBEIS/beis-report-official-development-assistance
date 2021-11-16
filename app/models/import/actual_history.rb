class Import::ActualHistory
  class RowError < StandardError
    attr_reader :row_number

    def initialize(message, row_number)
      @row_number = row_number
      super(message)
    end
  end

  VALID_HEADERS = {
    roda_identifier: "RODA identifier",
    financial_quarter: "Financial quarter",
    financial_year: "Financial year",
    value: "Value",
  }

  attr_reader :errors, :imported

  def initialize(report:, csv:)
    @report = report
    @headers = csv.headers
    @csv = csv
    @imported = []
    @errors = []
  end

  def call
    import_actual_history(@csv)
  end

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

    true
  end

  def headers_valid?
    @headers == VALID_HEADERS.values
  end

  def headers_error
    RowError.new("Invalid headers, must be #{VALID_HEADERS.values.to_sentence}", 1)
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
      RowError
        .new(
          "Activity with RODA ID #{activity.roda_identifier} does not match the fund and organisation of this report",
          row_number
        )
    end

    def roda_identifier
      @row.field("RODA identifier").strip
    end

    def roda_identifier_valid?
      activity.present? ? true : false
    end

    def roda_identifier_error
      RowError.new("Unknown RODA identifier #{roda_identifier}", row_number)
    end

    def active_model_to_import_errors_for_row(errors)
      errors.map { |error| RowError.new(error.message, row_number) }
    end
  end
end
