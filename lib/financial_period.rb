module FinancialPeriod
  FINANCIAL_QUARTERS = (1..4).to_a

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

  def self.current_financial_quarter
    quarter_from_date(Date.today)
  end

  def self.current_financial_year
    year_from_date(Date.today)
  end

  def self.next_ten_years
    this_year = current_financial_year.to_i
    tenth_year = this_year + 9
    (this_year..tenth_year).step.to_a
  end

  def self.start_date_from_quarter_and_year(financial_quarter, financial_year)
    first_month_of_quarter = {"1": "April", "2": "July", "3": "October", "4": "January"}
    year_of_quarter = financial_quarter == "4" ? financial_year.to_i + 1 : financial_year
    "#{first_month_of_quarter[financial_quarter.to_sym]} #{year_of_quarter}".to_date.beginning_of_quarter
  end

  def self.end_date_from_quarter_and_year(financial_quarter, financial_year)
    last_month_of_quarter = {"1": "June", "2": "September", "3": "December", "4": "March"}
    year_of_quarter = financial_quarter == "4" ? financial_year.to_i + 1 : financial_year
    "#{last_month_of_quarter[financial_quarter.to_sym]} #{year_of_quarter}".to_date.end_of_quarter
  end
end
