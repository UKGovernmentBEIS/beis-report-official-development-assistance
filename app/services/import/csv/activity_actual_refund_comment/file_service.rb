class Import::Csv::ActivityActualRefundComment::FileService
  REQUIRED_HEADERS = [
    "Activity RODA Identifier",
    "Financial Quarter",
    "Financial Year",
    "Actual Value",
    "Refund Value",
    "Comment"
  ].freeze

  attr_reader :errors, :imported_rows

  def initialize(report:, user:, csv_rows:)
    @report = report
    @user = user
    @errors = []
    @csv_rows = csv_rows
    @imported_rows = []
  end

  def import!
    return false unless valid_headers?

    ActiveRecord::Base.transaction do
      @imported_rows = @csv_rows.filter_map.with_index do |csv_row, index|
        row_importer = Import::Csv::ActivityActualRefundComment::RowService.new(@report, @user, csv_row)

        imported_row = row_importer.import!

        collate_errors_from_row_importer(index, row_importer) if row_importer.errors.any?

        Import::Csv::ImportedRow.new(index, imported_row)
      end

      unless @errors.empty?
        @imported_rows = []
        raise ActiveRecord::Rollback
      end
    end
    @imported_rows.any?
  end

  def imported_actuals
    @imported_rows.filter_map do |row|
      row.object if row.object.is_a?(Actual)
    end
  end

  def imported_refunds
    @imported_rows.filter_map do |row|
      row.object if row.object.is_a?(Refund)
    end
  end

  def imported_comments
    @imported_rows.filter_map do |row|
      row.object if row.object.is_a?(Comment)
    end
  end

  def skipped_rows
    @imported_rows.select do |row|
      row.object.is_a?(Import::Csv::ActivityActualRefundComment::SkippedRow)
    end
  end

  private def valid_headers?
    REQUIRED_HEADERS.to_set.subset?(@csv_rows.headers.to_set)
  end

  private def collate_errors_from_row_importer(index, row)
    row.errors.each do |attr_name, (value, message)|
      @errors << Import::RowError.new(column: attr_name, row_number: index, value: value, message: message)
    end
  end
end
