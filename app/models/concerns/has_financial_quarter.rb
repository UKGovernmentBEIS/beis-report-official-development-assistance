module HasFinancialQuarter
  extend ActiveSupport::Concern

  def later_period_than?(other)
    return true if other&.financial_period.blank?

    financial_period.last > other.financial_period.last
  end

  def own_financial_quarter
    if financial_year.present? && financial_quarter.present?
      FinancialQuarter.new(financial_year, financial_quarter)
    end
  end

  def financial_quarter_and_year
    own_financial_quarter&.to_s
  end

  def financial_period
    return if own_financial_quarter.nil?
    (own_financial_quarter.start_date..own_financial_quarter.end_date)
  end

  def first_day_of_financial_period
    own_financial_quarter.start_date
  end
end
