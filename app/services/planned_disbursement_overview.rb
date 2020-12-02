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
    Snapshot.non_zero_forecasts_from(latest_values_relation)
  end

  def latest_values_relation
    if record_history?
      latest_with_report_versioning
    else
      latest_unversioned
    end
  end

  def snapshot(report)
    unless record_history?
      raise TypeError, "Cannot retrieve history for unversioned activities"
    end

    Snapshot.new(self, report)
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
      .where(parent_activity_id: @activity.id)
      .order(financial_year: :asc, financial_quarter: :asc)
  end

  class Snapshot
    def self.non_zero_forecasts_from(relation)
      PlannedDisbursement.from(relation, :planned_disbursements).where.not(value: 0)
    end

    def initialize(overview, report)
      @overview = overview
      @report = report
    end

    def all_quarters
      relation = @overview.latest_values_relation.merge(Report.historically_up_to(@report))
      Snapshot.non_zero_forecasts_from(relation)
    end

    def value_for_report_quarter
      lookup_value_for_quarter(@report.financial_quarter, @report.financial_year)
    end

    def value_for(financial_quarter:, financial_year:)
      lookup_value_for_quarter(financial_quarter, financial_year)
    end

    private

    def lookup_value_for_quarter(quarter, year)
      all_quarters.where(financial_quarter: quarter, financial_year: year).sum(:value)
    end
  end
end
