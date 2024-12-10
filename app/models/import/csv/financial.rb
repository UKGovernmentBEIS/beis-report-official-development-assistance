class Import::Csv::Financial
  attr_reader :decimal_value, :original_value

  def initialize(value)
    @decimal_value = convert_to_decimal(value.to_s)
    @original_value = value.to_s
  end

  private def convert_to_decimal(value)
    return BigDecimal(0) if value.blank?

    begin
      converted_value = ConvertFinancialValue.new.convert(value)
    rescue ConvertFinancialValue::Error
      return nil
    end
    converted_value
  end
end
