class ConvertFinancialValue
  VALUE_FORMAT = /^(?:£ *)?((?:- *)?[0-9,]+(?:\.[0-9]{1,2})?)$/

  Error = Class.new(StandardError)

  def convert(value)
    match = VALUE_FORMAT.match(value.strip)
    raise Error if match.nil?

    numeric = match[1].gsub(/[, ]/, "")
    BigDecimal(numeric, 2)
  end
end
