class QuarterlyTransactionExport
  HEADERS = [
    "Activity RODA Identifier",
    "Activity BEIS Identifier",
  ]

  def initialize(activities)
    @activities = activities.to_a
    load_transactions
  end

  def headers
    return HEADERS if @transactions.empty?

    HEADERS + financial_quarter_range.map(&:to_s)
  end

  def rows
    @activities.map do |activity|
      [activity.roda_identifier, activity.beis_identifier] + transaction_row(activity)
    end
  end

  private

  def transaction_row(activity)
    return [] if @transactions.empty?

    financial_quarter_range.map do |quarter|
      value = @transactions[[activity.id, quarter]]&.value || 0
      "%.2f" % value
    end
  end

  def load_transactions
    group_columns = "parent_activity_id, financial_year, financial_quarter"

    txn_relation = Transaction
      .where(parent_activity: @activities)
      .group(group_columns)
      .select("#{group_columns}, SUM(value) AS value")

    @transactions = {}
    @financial_quarters = Set.new

    txn_relation.each do |txn|
      key = [txn.parent_activity_id, txn.own_financial_quarter]
      @transactions[key] = txn

      @financial_quarters.add(txn.own_financial_quarter)
    end
  end

  def financial_quarter_range
    @_financial_quarter_range ||= Range.new(*@financial_quarters.minmax)
  end
end
