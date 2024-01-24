class Import::Csv::ImportedRow
  attr_reader :csv_row_number, :object

  def initialize(index, object)
    @csv_row_number = index + 2
    @object = object
  end
end
