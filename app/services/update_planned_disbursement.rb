class UpdatePlannedDisbursement
  attr_accessor :planned_disbursement

  def initialize(planned_disbursement:)
    self.planned_disbursement = planned_disbursement
  end

  def call(attributes: {})
    planned_disbursement.assign_attributes(attributes)
    planned_disbursement.value = sanitize_monetary_string(value: attributes[:value])

    result = if planned_disbursement.valid?
      Result.new(planned_disbursement.save!, planned_disbursement)
    else
      Result.new(false, planned_disbursement)
    end

    result
  end

  private

  def sanitize_monetary_string(value:)
    Monetize.parse(value)
  end
end
