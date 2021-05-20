class PlannedDisbursementAggregate
  delegate :start_date, :end_date, to: :@financial_quarter, prefix: :period
  delegate :providing_organisation_type, :providing_organisation_name, :providing_organisation_reference, to: "@planned_disbursements.first"

  def initialize(financial_quarter, planned_disbursements)
    @financial_quarter = financial_quarter
    @planned_disbursements = planned_disbursements
  end

  def planned_disbursement_type
    "original"
  end

  def currency
    @planned_disbursements.first.currency
  end

  def value
    @planned_disbursements.sum(&:value)
  end
end
