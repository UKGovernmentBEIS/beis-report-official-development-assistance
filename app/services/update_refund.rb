class UpdateRefund
  def initialize(refund:)
    @refund = refund
  end

  def call(attributes: {})
    assign_refund_and_comment(attributes)
    success = refund.save

    if success
      Result.new(true, refund)
    else
      Result.new(false, refund)
    end
  end

  private

  attr_reader :refund

  def assign_refund_and_comment(attrs)
    refund.comment.body = attrs.delete(:comment)
    refund.value = attrs.delete(:value)&.to_s
    refund.assign_attributes(attrs)
  end
end
