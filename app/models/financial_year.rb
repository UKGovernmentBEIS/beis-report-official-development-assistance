class FinancialYear
  include Comparable

  class InvalidYear < StandardError; end

  attr_reader :start_year, :end_year

  def initialize(start_year)
    @start_year = DateTime.strptime(start_year.to_s, "%Y").year
    @end_year = @start_year + 1
  rescue ArgumentError
    raise InvalidYear
  end

  class << self
    def for_date(date)
      if [1, 2, 3].include?(date.month)
        new(date.year - 1)
      else
        new(date.year)
      end
    end

    def next_ten
      this_financial_year = for_date(Date.today).to_i
      tenth_year = this_financial_year + 9

      (this_financial_year..tenth_year).map { |year| new(year) }
    end

    def previous_ten
      this_financial_year = for_date(Date.today).to_i
      first_year = this_financial_year - 9

      (first_year..this_financial_year).map { |year| new(year) }
    end

    def from_twenty_ten_to_ten_years_ahead
      twenty_ten = for_date(Date.parse("2011-01-01")).to_i
      ten_years_ahead = for_date(Date.today).to_i + 9

      (twenty_ten..ten_years_ahead).map { |year| new(year) }
    end
  end

  def <=>(other)
    start_year <=> other.start_year
  end

  def ==(other)
    start_year == other.start_year
  end

  def start_date
    Date.new(start_year, 4, 1)
  end

  def end_date
    Date.new(end_year, 3, 31)
  end

  def to_i
    start_year
  end

  def to_s
    [start_year, end_year].join("-")
  end

  def quarters
    FinancialQuarter::QUARTERS.map { |q| FinancialQuarter.new(start_year, q) }
  end

  def pred
    FinancialYear.new(start_year - 1)
  end

  def succ
    FinancialYear.new(start_year + 1)
  end
end
