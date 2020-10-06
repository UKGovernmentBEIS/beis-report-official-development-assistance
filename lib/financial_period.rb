module FinancialPeriod
  def self.quarter_from_date(date)
    month = date.month
    case month
    when 1, 2, 3
      "4"
    when 4, 5, 6
      "1"
    when 7, 8, 9
      "2"
    when 10, 11, 12
      "3"
    end
  end

  def self.year_from_date(date)
    month = date.month
    year = date.year
    if (4..12).cover?(month)
      return year.to_s
    end
    (year - 1).to_s
  end
end
