class CsvFileUpload
  BYTE_ORDER_MARK = "\uFEFF".encode(Encoding::UTF_8)

  attr_reader :file, :error

  def initialize(params, atttibute_name)
    @file = params&.fetch(atttibute_name, nil)
  end

  def rows
    @rows ||= parse_csv
  end

  def valid?
    rows.present?
  end

  private def parse_csv
    return nil unless file

    CSV.parse(body, headers: true)
  rescue
    nil
  end

  private def body
    contents = file.read.force_encoding(Encoding::UTF_8)
    contents.delete_prefix!(BYTE_ORDER_MARK)
    contents
  end
end
