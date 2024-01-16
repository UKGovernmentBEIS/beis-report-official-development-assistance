class Import::RowError < StandardError
  attr_reader :row_number, :column, :value, :csv_row_number

  def initialize(column:, row_number:, value:, message:)
    @row_number = row_number
    @column = column
    @value = value
    @csv_row_number = row_number + 2
    super(message)
  end
end
