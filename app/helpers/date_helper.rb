module DateHelper
  class InvalidDateError < StandardError; end

  def format_date(params)
    date_parts = params.values_at(:day, :month, :year)
    return unless date_parts.all?(&:present?)

    day, month, year = date_parts.map(&:to_i)
    Date.new(year, month, day)
  rescue ArgumentError
    nil
  end

  def validated_date(params)
    date_parts = params.values_at(:day, :month, :year)
    return if date_parts.all?(&:blank?)

    raise InvalidDateError unless date_parts.all?(&:present?)

    day, month, year = date_parts.map(&:to_i)
    Date.new(year, month, day)
  rescue ArgumentError
    raise InvalidDateError
  end
end
