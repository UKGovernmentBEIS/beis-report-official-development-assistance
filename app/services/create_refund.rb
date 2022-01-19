class CreateRefund
  class Error < StandardError; end

  attr_accessor :activity, :report, :refund, :user

  def initialize(activity:, user:)
    self.activity = activity
    self.user = user
    self.refund = Refund.new
  end

  def call(attributes:)
    refund.parent_activity = activity
    refund.report = editable_report_for(activity)
    assign_refund_and_comment(attributes)
    refund.save

    raise Error, validation_error_message(refund) if refund.errors.any?

    record_historical_event(refund)

    refund
  end

  private

  def assign_refund_and_comment(attrs)
    refund.build_comment(
      body: attrs.delete(:comment),
      commentable: refund,
      report: refund.report
    )
    refund.value = attrs.delete(:value)&.to_s
    refund.assign_attributes(attrs)
  end

  def validation_error_message(refund)
    refund.errors.map { |error| error.message }.join("; ")
  end

  def editable_report_for(activity)
    report = Report.editable_for_activity(activity)
    raise Error, "There is no editable report for this activity" unless report

    report
  end

  def record_historical_event(refund)
    HistoryRecorder.new(user: user).call(
      changes: changes_to_tracked_attributes(refund),
      reference: "Creation of Refund",
      activity: refund.parent_activity,
      trackable: refund,
      report: refund.report
    )
  end

  def changes_to_tracked_attributes(refund)
    {
      value: [nil, refund.value],
      financial_quarter: [nil, refund.financial_quarter],
      financial_year: [nil, refund.financial_year],
      comment: [nil, refund.comment.body]
    }
  end
end
