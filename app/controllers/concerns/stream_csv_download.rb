module StreamCsvDownload
  extend ActiveSupport::Concern
  include ActionController::Live

  def stream_csv_download(filename:, headers:)
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{filename}"

    writer = Writer.new(response.stream)
    writer << headers
    yield writer if block_given?

    response.stream.close
  end

  class Writer
    DEFAULT_ENCODING = Encoding::UTF_8
    BYTE_ORDER_MARK = "\uFEFF"

    def initialize(stream)
      @stream = stream
      @stream.write(encode(BYTE_ORDER_MARK))
    end

    def <<(row)
      @stream.write(encode(CSV.generate_line(row)))
    end

    private

    def encode(string)
      string.encode(DEFAULT_ENCODING)
    end
  end
end
