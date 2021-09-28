module TransactionOverview
  def initialize(report:, include_adjustments: false)
    @report = report
    @include_adjustments = include_adjustments
  end

  def all_quarters
    group_fields = "transactions.financial_year, transactions.financial_quarter, transactions.parent_activity_id"

    relation = actual_relation
      .group(group_fields)
      .select("#{group_fields}, SUM(value) AS value")

    AllQuarters.new(relation)
  end

  def value_for_report_quarter(activity)
    value_for(activity: activity, **@report.own_financial_quarter)
  end

  def value_for(financial_quarter:, financial_year:, activity:)
    actual_relation
      .where(
        financial_quarter: financial_quarter,
        financial_year: financial_year,
        parent_activity: activity
      )
      .sum(:value)
  end

  private

  def actual_relation
    scope
      .joins(:report)
      .merge(Report.historically_up_to(@report))
  end

  def scope
    scope = Transaction.where(type: transaction_class)

    if @include_adjustments
      scope = scope
        .with_adjustment_details
        .or(
          Transaction
            .where(
              type: "Adjustment",
              adjustment_details: {adjustment_type: transaction_class}
            )
        )
    end

    scope
  end

  def transaction_class
    @transaction_class ||= self.class.name.split("::").first
  end

  class AllQuarters
    def initialize(relation)
      @index = {}

      relation.each do |record|
        @index[[record.financial_quarter, record.financial_year, record.parent_activity_id]] = record.value
      end
    end

    def value_for(financial_quarter:, financial_year:, activity:)
      @index.fetch([financial_quarter, financial_year, activity.id], 0)
    end
  end
end
