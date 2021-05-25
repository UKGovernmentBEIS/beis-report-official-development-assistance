class PlannedDisbursementAggregate
  delegate :start_date, :end_date, to: :@financial_quarter, prefix: :period

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

  def providing_organisation_name
    providing_organisation.name
  end

  def providing_organisation_type
    providing_organisation.organisation_type
  end

  def providing_organisation_reference
    providing_organisation.iati_reference
  end

  private def providing_organisation
    @_providing_organisation ||= Organisation.service_owner
  end
end
