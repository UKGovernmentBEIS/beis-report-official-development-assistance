class ImportConverter
  TRANSACTION_HEADER_PATTERNS = [
    /^Act +(?<year>\d{4})\/\d{2} +FY +Q(?<quarter>[1-4]) +\(.*\)$/,
    /^Act +(?<year>\d{4})\/\d{2} +Q(?<quarter>[1-4])$/,
    /^Q(?<quarter>[1-4]) +(?<year>\d{4})-\d{4} actuals$/,
  ]

  FORECAST_HEADER_PATTERNS = [
    /^FC +Q(?<quarter>[1-4]) +(?<year>\d{4})-\d{2}$/,
    /^FC +Q(?<quarter>[1-4]) +(?<year>\d{4})$/,
    /^FC +(?<year>\d{4})\/\d{2} +FY +Q(?<quarter>[1-4]) +\(.*\)$/,
    /^Q(?<quarter>[1-4]) +(?<year>\d{4})-\d{4} forecast$/,
  ]

  IDENTIFIER_HEADERS = ["Activity RODA Identifier"]
  TRANSACTION_HEADERS = ["Financial Year", "Financial Quarter", "Value"].freeze

  LEVEL_C = "C"
  LEVEL_D = "D"

  def initialize(row, level:, forecast_mappings: nil)
    @row = row
    @level = level
    @forecast_mappings = forecast_mappings
  end

  def transaction_headers
    IDENTIFIER_HEADERS + TRANSACTION_HEADERS
  end

  def transaction_tuples
    tuples = []

    @row.each do |header, value|
      next if value.blank?
      year, quarter = match_quarter(header, TRANSACTION_HEADER_PATTERNS)

      if year && quarter && value.strip != "0"
        tuples << identifier_tuple + [year, quarter, value]
      end
    end

    tuples
  end

  def forecast_headers
    IDENTIFIER_HEADERS + forecast_mappings.map(&:first)
  end

  def forecast_tuples
    tuple = forecast_mappings.map { |_, row_header| @row.fetch(row_header) }
    [identifier_tuple + tuple]
  end

  def forecast_mappings
    return @forecast_mappings if @forecast_mappings
    @forecast_mappings = []

    @row.each do |row_header, _|
      year, quarter = match_quarter(row_header, FORECAST_HEADER_PATTERNS)
      next unless year && quarter

      output_header = forecast_header(year, quarter)
      @forecast_mappings << [output_header, row_header]
    end

    @forecast_mappings.sort_by!(&:first)
    @forecast_mappings
  end

  private

  def identifier_tuple
    separator = case @level
      when LEVEL_C then "-"
      when LEVEL_D then ""
    end

    id_parts = ["Parent RODA ID", "RODA ID Fragment"].map { |key| @row.fetch(key) }
    [id_parts.join(separator)]
  end

  def forecast_header(year, quarter)
    next_year = (year.to_i + 1) % 100
    "FC #{year}/#{next_year} FY Q#{quarter}"
  end

  def match_quarter(header, patterns)
    patterns.each do |pattern|
      match = pattern.match(header)
      return [match[:year], match[:quarter]] if match
    end

    nil
  end
end
