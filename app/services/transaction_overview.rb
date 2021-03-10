class TransactionOverview
  def initialize(activity, report)
    @activity = activity
    @report = report
  end

  def all_quarters
    group_fields = "transactions.financial_year, transactions.financial_quarter"

    relation = transaction_relation
      .group(group_fields)
      .select("#{group_fields}, SUM(value) AS value")

    AllQuarters.new(relation)
  end

  def value_for_report_quarter
    value_for(**@report.own_financial_quarter)
  end

  def value_for(financial_quarter:, financial_year:)
    transaction_relation
      .where(financial_quarter: financial_quarter, financial_year: financial_year)
      .sum(:value)
  end

  private

  def transaction_relation
    Transaction
      .joins(:report)
      .where(parent_activity_id: @activity.id)
      .merge(Report.historically_up_to(@report))
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
