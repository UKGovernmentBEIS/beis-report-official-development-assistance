class AddFinancialQuarterAndYearToPlannedDisbursements < ActiveRecord::Migration[6.0]
  def change
    add_column :planned_disbursements, :financial_quarter, :integer, index: true
    add_column :planned_disbursements, :financial_year, :integer, index: true

    reversible do |change|
      change.up do
        planned_disbursements = PlannedDisbursement.all

        planned_disbursements.each do |planned_disbursement|
          financial_quarter = FinancialQuarter.for_date(planned_disbursement.period_start_date)
          financial_year = FinancialYear.for_date(planned_disbursement.period_start_date)

          planned_disbursement.financial_quarter = financial_quarter.to_i
          planned_disbursement.financial_year = financial_year.to_i
          planned_disbursement.save(validate: false)
        end
      end
    end
  end
end
