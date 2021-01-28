class SetFinancialYearBasedOnStartDate < ActiveRecord::Migration[6.0]
  def up
    Budget.all.find_each do |budget|
      financial_year = budget.period_start_date.present? ? FinancialYear.new(budget.period_start_date).to_i : 2020
      budget.update_columns(financial_year: financial_year)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
