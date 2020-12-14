class LinkProjectForecastsToReports < ActiveRecord::Migration[6.0]
  def up
    level_c_or_d_forecasts.where(report_id: nil).each do |planned_disbursement|
      reports = historic_reports_for_activity(planned_disbursement.parent_activity)

      if reports.count == 1
        pds = PlannedDisbursement.where(id: planned_disbursement.id)
        pds.update_all(report_id: reports.first.id)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def level_c_or_d_forecasts
    PlannedDisbursement
      .joins(:parent_activity)
      .where(activities: {level: %w[project third_party_project]})
  end

  def historic_reports_for_activity(activity)
    Report.for_activity(activity).where(financial_quarter: nil, financial_year: nil)
  end
end
