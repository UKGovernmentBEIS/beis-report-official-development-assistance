class CreateRefund
  attr_accessor :activity, :report, :refund

  def initialize(activity:)
    self.activity = activity
    self.report = Report.editable_for_activity(activity)
    self.refund = Refund.new
  end

  def call(attributes:)
    refund.parent_activity = activity
    refund.report = report
    assign_refund_and_comment(attributes)

    result = if refund.valid?
      Result.new(refund.save, refund)
    else
      Result.new(false, refund)
    end

    result
  end

  private

  def assign_refund_and_comment(attrs)
    refund.build_comment(comment: attrs.delete(:comment), commentable: refund)
    refund.value = attrs.delete(:value)&.to_s
    refund.assign_attributes(attrs)
  end
end
