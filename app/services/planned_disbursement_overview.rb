class PlannedDisbursementOverview
  LATEST_ENTRY_PER_QUARTER = <<~SQL
    DISTINCT ON (
      planned_disbursements.financial_year,
      planned_disbursements.financial_quarter
    )
    planned_disbursements.*
  SQL

  def initialize(activity)
    @activity = activity
  end

  def latest_values
    if record_history?
      latest_with_report_versioning
    else
      latest_unversioned
    end
  end

  def values_at_report(report)
    unless record_history?
      raise TypeError, "Cannot retrieve history for unversioned activities"
    end

    latest_values.merge(Report.historically_up_to(report))
  end

  def value_for_report(report)
    forecasts_for_report_quarter = values_at_report(report).where(
      financial_quarter: report.financial_quarter,
      financial_year: report.financial_year
    )
    PlannedDisbursement.from(forecasts_for_report_quarter).sum(:value)
  end

  private

  def record_history?
    !@activity.organisation.service_owner?
  end

  def latest_with_report_versioning
    historical_entries.joins(:report).merge(Report.in_historical_order)
  end

  def latest_unversioned
    historical_entries.order(planned_disbursement_type: :desc)
  end

  def historical_entries
    PlannedDisbursement
      .select(LATEST_ENTRY_PER_QUARTER)
      .where(parent_activity: @activity)
      .order(financial_year: :asc, financial_quarter: :asc)
  end
end
