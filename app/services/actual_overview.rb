class ActualOverview
  def initialize(activity:, report:, include_adjustments: false)
    @activity = activity
    @report = report
    @include_adjustments = include_adjustments
  end

  def all_quarters
    group_fields = "transactions.financial_year, transactions.financial_quarter"

    relation = actual_relation
      .group(group_fields)
      .select("#{group_fields}, SUM(value) AS value")

    AllQuarters.new(relation)
  end

  def value_for_report_quarter
    value_for(**@report.own_financial_quarter)
  end

  def value_for(financial_quarter:, financial_year:)
    actual_relation
      .where(financial_quarter: financial_quarter, financial_year: financial_year)
      .sum(:value)
  end

  private

  def actual_relation
    scope
      .joins(:report)
      .where(parent_activity_id: @activity.id)
      .merge(Report.historically_up_to(@report))
  end

  def scope
    if @include_adjustments
      Transaction
        .joins("LEFT OUTER JOIN adjustment_details ON transactions.id = adjustment_details.adjustment_id")
        .where(type: "Actual")
        .or(
          Transaction
            .where(
              type: "Adjustment",
              adjustment_details: {adjustment_type: "Actual"}
            )
        )
    else
      Actual
    end
  end

  class AllQuarters
    def initialize(relation)
      @index = {}

      relation.each do |record|
        @index[[record.financial_quarter, record.financial_year]] = record.value
      end
    end

    def value_for(financial_quarter:, financial_year:)
      @index.fetch([financial_quarter, financial_year], 0)
    end
  end
end
