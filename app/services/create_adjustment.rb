class CreateAdjustment
  class AdjustmentError < RuntimeError; end

  def initialize(activity:)
    @activity = activity
  end

  def call(attributes:)
    @attributes = attributes
    bail_if_report_not_acceptable

    adjustment = create_adjustment
    result = if adjustment.errors.any?
      Result.new(false, adjustment)
    else
      Result.new(true, adjustment)
    end

    result
  end

  private

  attr_reader :activity, :attributes

  def create_adjustment
    Adjustment.new(adjustment_attrs).tap do |adjustment|
      adjustment.build_comment(
        body: attributes.fetch(:comment),
        commentable: adjustment
      )
      adjustment.build_detail(
        user: attributes.fetch(:user),
        adjustment_type: attributes.fetch(:adjustment_type)
      )
      adjustment.save
    end
  end

  def adjustment_attrs
    {
      parent_activity: activity,
      report: report,
      value: attributes.fetch(:value),
      financial_quarter: attributes.fetch(:financial_quarter),
      financial_year: attributes.fetch(:financial_year),
    }
  end

  def bail_if_report_not_acceptable
    if report.state != "active"
      msg = "Report ##{report.id} is not in the active state"
    end
    unless valid_reports_for_activity.include?(report)
      msg = "Report ##{report.id} is not associated with Activity ##{activity.id}"
    end

    raise AdjustmentError, msg if msg
  end

  def report
    attributes.fetch(:report)
  end

  def valid_reports_for_activity
    Report.for_activity(activity)
  end
end
