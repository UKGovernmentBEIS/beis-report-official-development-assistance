class AddFinancialQuarterAndYearToPlannedDisbursements < ActiveRecord::Migration[6.0]
  def change
    add_column :planned_disbursements, :financial_quarter, :integer, index: true
    add_column :planned_disbursements, :financial_year, :integer, index: true

    reversible do |change|
      change.up do
        planned_disbursements = PlannedDisbursement.all

        planned_disbursements.each do |planned_disbursement|
          financial_quarter = FinancialPeriod.quarter_from_date(planned_disbursement.period_start_date)
          financial_year = FinancialPeriod.year_from_date(planned_disbursement.period_start_date)

          planned_disbursement.financial_quarter = financial_quarter
          planned_disbursement.financial_year = financial_year
          planned_disbursement.save(validate: false)
        end
      end
    end
  end
end
