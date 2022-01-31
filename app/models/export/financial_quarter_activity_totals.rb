class Export::FinancialQuarterActivityTotals
  TYPES = {
    actual: "Actual",
    refund: "Refund"
  }

  def initialize(type:, activity:, totals:, financial_quarter:)
    @transaction_type = TYPES.fetch(type)
    @activity = activity
    @totals = totals
    @financial_quarter = financial_quarter
  end

  def net_total
    total + adjustments_total
  end

  def total
    @totals.fetch([
      @activity.id,
      @financial_quarter.quarter,
      @financial_quarter.financial_year.start_year,
      @transaction_type,
      nil
    ], 0)
  end

  def adjustments_total
    @totals.fetch([
      @activity.id,
      @financial_quarter.quarter,
      @financial_quarter.financial_year.start_year,
      "Adjustment",
      @transaction_type
    ], 0)
  end
end
