class PlannedDisbursementOverview
  LATEST_ENTRY_PER_ACTIVITY_AND_QUARTER = <<~SQL
    DISTINCT ON (
      planned_disbursements.parent_activity_id,
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
    @activity.is_a?(Array) || !@activity.organisation.service_owner?
  end

  def latest_with_report_versioning
    historical_entries
      .left_outer_joins(:report)
      .merge(Report.in_historical_order)
      .order(planned_disbursement_type: :desc)
  end

  def latest_unversioned
    historical_entries.order(planned_disbursement_type: :desc)
  end

  def historical_entries
    PlannedDisbursement
      .unscoped
      .select(LATEST_ENTRY_PER_ACTIVITY_AND_QUARTER)
      .where(parent_activity_id: activity_ids)
      .order(parent_activity_id: :asc, financial_year: :asc, financial_quarter: :asc)
  end

  def activity_ids
    [*@activity].map(&:to_param)
  end

  class Snapshot
    def self.non_zero_forecasts_from(relation)
      PlannedDisbursement.unscoped.from(relation, :planned_disbursements).where.not(value: 0)
    end

    def initialize(overview, report)
      @overview = overview
      @report = report
    end

    def all_quarters
      AllQuarters.new(all_quarters_relation)
    end

    def value_for_report_quarter
      quarter, year = @report.financial_quarter, @report.financial_year
      all_quarters_relation.where(financial_quarter: quarter, financial_year: year).sum(:value)
    end

    private

    def all_quarters_relation
      relation = @overview.latest_values_relation.merge(Report.historically_up_to(@report))
      Snapshot.non_zero_forecasts_from(relation)
    end
  end

  class AllQuarters
    def initialize(relation)
      @index = Hash.new { |hash, key| hash[key] = [] }

      relation.each do |record|
        @index[[record.financial_quarter, record.financial_year]] << record
      end
    end

    def as_records
      @index.values.reduce(&:concat)
    end

    def value_for(financial_quarter:, financial_year:)
      @index.fetch([financial_quarter, financial_year], []).map(&:value).sum
    end
  end
end
