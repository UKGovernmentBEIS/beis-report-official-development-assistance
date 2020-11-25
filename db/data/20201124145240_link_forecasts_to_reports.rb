class LinkForecastsToReports < ActiveRecord::Migration[6.0]
  def up
    level_a_or_b_forecasts.update_all(report_id: nil)

    level_c_or_d_forecasts.where(report_id: nil).each do |planned_disbursement|
      reports = historic_reports_for_activity(planned_disbursement.parent_activity)

      if reports.count == 1
        planned_disbursement.update!(report: reports.first)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def level_a_or_b_forecasts
    PlannedDisbursement
      .includes(:parent_activity)
      .where(activities: {level: %w[fund programme]})
  end

  def level_c_or_d_forecasts
    PlannedDisbursement
      .includes(:parent_activity)
      .where(activities: {level: %w[project third_party_project]})
  end

  def historic_reports_for_activity(activity)
    Report.where(
      fund_id: activity.associated_fund.id,
      organisation_id: activity.organisation_id,
      financial_quarter: nil,
      financial_year: nil,
    )
  end
end
