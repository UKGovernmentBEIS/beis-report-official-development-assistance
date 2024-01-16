class Import::RowError < StandardError
  attr_reader :row_number, :column, :value, :csv_row_number, :csv_row

  def initialize(column:, row_number:, value:, message:)
    @row_number = row_number
    @column = column
    @value = value
    @csv_row_number = row_number + 2
    # csv_row to stay compatible with the current importer UI so we can switch between the two
    @csv_row = @csv_row_number
    super(message)
  end
end
