class CreateRefund
  class Error < StandardError; end

  attr_accessor :activity, :report, :refund

  def initialize(activity:)
    self.activity = activity
    self.refund = Refund.new
  end

  def call(attributes:)
    refund.parent_activity = activity
    refund.report = editable_report_for(activity)
    assign_refund_and_comment(attributes)
    refund.save

    raise Error, validation_error_message(refund) if refund.errors.any?

    refund
  end

  private

  def assign_refund_and_comment(attrs)
    refund.build_comment(body: attrs.delete(:comment), commentable: refund)
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
end
