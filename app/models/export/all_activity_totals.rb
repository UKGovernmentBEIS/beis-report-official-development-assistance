class Export::AllActivityTotals
  attr_reader :totals

  def initialize(activity:, report: nil)
    @activity = activity
    @scoped_to_report = report
    @totals = nil
  end

  def call
    apply_base_scope
    apply_report_scope unless @scoped_to_report.nil?
    apply_select
    apply_grouping
    apply_ordering
    apply_sum_totals

    totals
  end

  private

  def apply_base_scope
    @totals = Transaction
      .joins("LEFT OUTER JOIN adjustment_details ON adjustment_details.adjustment_id = transactions.id")
      .where(parent_activity_id: @activity.id)
  end

  def apply_report_scope
    @totals = @totals
      .where(report_id: Report.historically_up_to(@scoped_to_report).pluck(:id))
  end

  def apply_select
    @totals = @totals
      .select(
        :financial_quarter,
        :financial_year,
        :parent_activity_id,
        :value,
        :type,
        "adjustment_details.adjustment_type"
      )
  end

  def apply_grouping
    @totals = @totals.group(
      :parent_activity_id,
      :financial_quarter,
      :financial_year,
      :type,
      "adjustment_details.adjustment_type"
    )
  end

  def apply_ordering
    @totals = @totals.order(:parent_activity_id, :financial_quarter, :financial_year)
  end

  def apply_sum_totals
    @totals = @totals.sum(:value)
  end
end
