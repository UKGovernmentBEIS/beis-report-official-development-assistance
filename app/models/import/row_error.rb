class Import::RowError < StandardError
  attr_reader :row_number, :column, :value

  def initialize(column:, row_number:, value:, message:)
    @row_number = row_number
    @column = column
    @value = value
    super(message)
  end
end
