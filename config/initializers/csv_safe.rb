require "csv-safe"

class CSVSafe
  def sanitize_field(field)
    # we may represent monetary numerics as strings to format them, and we don't want CSVSafe to prefix these fields
    if field.nil? || field.is_a?(Numeric) || field_is_monetary?(field)
      field
    else
      prefix_if_necessary(field)
    end
  end

  def field_is_monetary?(field)
    field.is_a?(String) && Regexp.new(/\A[-\d.,]+\z/).match?(field)
  end
end
