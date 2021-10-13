class UpdateRefund
  def initialize(refund:, user:)
    @refund = refund
    @user = user
  end

  def call(attributes: {})
    assign_refund_and_comment(attributes)
    changes = refund.changes
    changes[:comment] = refund.comment.changes[:body] if refund.comment.changes[:body]
    success = refund.save

    if success
      record_historical_event(changes)
      Result.new(true, refund)
    else
      Result.new(false, refund)
    end
  end

  private

  attr_reader :refund, :user

  def assign_refund_and_comment(attrs)
    refund.comment.body = attrs.delete(:comment)
    refund.value = attrs.delete(:value)&.to_s
    refund.assign_attributes(attrs)
  end

  def record_historical_event(changes)
    HistoryRecorder.new(user: user).call(
      changes: changes,
      reference: "Update to Refund",
      activity: refund.parent_activity,
      trackable: refund,
      report: refund.report
    )
  end
end
