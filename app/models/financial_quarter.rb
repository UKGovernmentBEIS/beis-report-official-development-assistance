class FinancialQuarter
  include Comparable

  attr_reader :financial_year, :quarter

  QUARTERS = (1..4).to_a

  def initialize(financial_year, quarter)
    @financial_year = FinancialYear.new(financial_year)
    @quarter = quarter
  end

  class << self
    def for_date(date)
      year = date.year

      case date.month
      when 1, 2, 3
        quarter = 4
        year = date.year - 1
      when 4, 5, 6
        quarter = 1
      when 7, 8, 9
        quarter = 2
      when 10, 11, 12
        quarter = 3
      end

      new(year, quarter)
    end
  end

  def <=>(other)
    if financial_year == other.financial_year
      quarter <=> other.quarter
    else
      financial_year <=> other.financial_year
    end
  end

  def ==(other)
    quarter == other.quarter && financial_year == other.financial_year
  end

  def eql?(other)
    self == other
  end

  def hash
    to_s.hash
  end

  def start_date
    @start_date ||= Date.new(calendar_year, start_month, 1)
  end

  def end_date
    @end_date ||= Date.new(calendar_year, end_month, 1).at_end_of_month
  end

  def start_month
    @start_month ||= case quarter
    when 1
      4
    when 2
      7
    when 3
      10
    when 4
      1
    end
  end

  def end_month
    (start_date + 2.months).month
  end

  def calendar_year
    quarter == 4 ? financial_year.end_year : financial_year.start_year
  end

  def to_s
    "FQ#{quarter} #{financial_year}"
  end

  def to_i
    quarter
  end

  def to_hash
    {financial_quarter: quarter, financial_year: financial_year.start_year}
  end

  def pred
    if quarter == 1
      FinancialQuarter.new(financial_year.start_year - 1, 4)
    else
      FinancialQuarter.new(financial_year.start_year, quarter - 1)
    end
  end

  def succ
    if quarter == 4
      FinancialQuarter.new(financial_year.start_year + 1, 1)
    else
      FinancialQuarter.new(financial_year.start_year, quarter + 1)
    end
  end

  def preceding(n)
    quarter = self
    (1..n).map { quarter = quarter.pred }.reverse
  end

  def following(n)
    quarter = self
    (1..n).map { quarter = quarter.succ }
  end
end
