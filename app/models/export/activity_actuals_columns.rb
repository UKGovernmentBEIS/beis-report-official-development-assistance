class Export::ActivityActualsColumns
  def initialize(activities:, include_breakdown: false, report: nil)
    @activities = activities
    @include_breakdown = include_breakdown
    @report = report
  end

  def headers
    return [] if @activities.empty?

    financial_quarter_range.map { |financial_quarter|
      if @include_breakdown
        [
          "Actual spend #{financial_quarter}",
          "Refund #{financial_quarter}",
          "Actual net #{financial_quarter}",
        ]
      else
        ["Actual net #{financial_quarter}"]
      end
    }.flatten
  end

  def rows
    return [] if @activities.empty?

    @activities.map { |activity|
      actual_and_refund_data(activity)
    }.to_h
  end

  def last_financial_quarter
    financial_quarter_range.max
  end

  private

  def actual_and_refund_data(activity)
    build_columns(all_totals_for_activity(activity), activity)
  end

  def build_columns(totals, activity)
    columns = financial_quarter_range.map { |fq|
      actual_overview = Export::FinancialQuarterActivityTotals.new(type: :actual, activity: activity, totals: totals, financial_quarter: fq)
      refund_overview = Export::FinancialQuarterActivityTotals.new(type: :refund, activity: activity, totals: totals, financial_quarter: fq)

      net_total = actual_overview.net_total + refund_overview.net_total

      if @include_breakdown
        [actual_overview.net_total, refund_overview.net_total, net_total]
      else
        [net_total]
      end
    }
    [activity.id, columns.flatten]
  end

  def all_totals_for_activity(activity)
    Export::AllActivityTotals.new(activity: activity).call
  end

  def reports_up_to(report)
    return if report.nil?
    Report.historically_up_to(report).pluck(:id)
  end

  def actual_spend
    actual_spend_scope = Actual.where(parent_activity_id: activity_ids)
    actual_spend_scope = actual_spend_scope.where(report_id: reports_up_to(@report)) unless @report.nil?
    @_actual_spend ||= actual_spend_scope
  end

  def refunds
    refund_scope = Refund.where(parent_activity_id: activity_ids)
    refund_scope = refund_scope.where(report_id: reports_up_to(@report)) unless @report.nil?
    @_refunds ||= refund_scope
  end

  def activity_ids
    @activity_ids ||= @activities.pluck(:id)
  end

  def all_financial_quarters_with_acutals
    return [] unless actual_spend.present?
    actual_spend.map(&:own_financial_quarter).uniq
  end

  def all_financial_quarters_with_refunds
    return [] unless refunds.present?
    refunds.map(&:own_financial_quarter).uniq
  end

  def financial_quarters
    all_financial_quarters_with_acutals + all_financial_quarters_with_refunds
  end

  def financial_quarter_range
    @_financial_quarter_range ||= Range.new(*financial_quarters.minmax)
  end
end
