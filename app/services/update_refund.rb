class UpdateRefund
  def initialize(refund:)
    @refund = refund
  end

  def call(attributes: {})
    refund.assign_attributes(attributes)

    success = refund.save

    if success
      Result.new(true, refund)
    else
      Result.new(false, refund)
    end
  end

  private

  attr_reader :refund
end
