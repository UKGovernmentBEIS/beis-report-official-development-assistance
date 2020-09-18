class AssociateAllIngestedEntitiesWithReports < ActiveRecord::Migration[6.0]
  def up
    Organisation.where(service_owner: false).each do |organisation|
      ingested_activities = Activity.where(ingested: true, organisation: organisation)
      ingested_activities.each do |activity|
        fund = activity.associated_fund
        report = Report.where(financial_quarter: nil).find_by(fund: fund, organisation: organisation)
        if report.present?
          activity.transactions.update_all(report_id: report.id)
          activity.budgets.update_all(report_id: report.id)
          activity.planned_disbursements.update_all(report_id: report.id)
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
