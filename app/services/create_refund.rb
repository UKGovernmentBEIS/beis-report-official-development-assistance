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
    refund.assign_attributes(attributes)

    result = if refund.valid?
      Result.new(refund.save, refund)
    else
      Result.new(false, refund)
    end

    result
  end
end
