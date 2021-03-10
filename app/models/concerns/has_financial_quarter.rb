module HasFinancialQuarter
  extend ActiveSupport::Concern

  def own_financial_quarter
    if financial_year.present? && financial_quarter.present?
      FinancialQuarter.new(financial_year, financial_quarter)
    end
  end

  def financial_quarter_and_year
    own_financial_quarter&.to_s
  end
end
