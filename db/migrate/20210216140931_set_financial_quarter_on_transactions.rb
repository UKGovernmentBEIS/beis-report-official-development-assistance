class SetFinancialQuarterOnTransactions < ActiveRecord::Migration[6.0]
  def up
    Transaction.where.not(date: nil).find_each do |transaction|
      financial_quarter = FinancialQuarter.for_date(transaction.date)

      transaction.update_columns(
        financial_quarter: financial_quarter.quarter,
        financial_year: financial_quarter.financial_year.start_year
      )
    end
  end
end
