class ForecastAggregate
  delegate :start_date, :end_date, to: :@financial_quarter, prefix: :period

  def initialize(financial_quarter, forecasts)
    @financial_quarter = financial_quarter
    @forecasts = forecasts
  end

  def forecast_type
    "original"
  end

  def currency
    @forecasts.first.currency
  end

  def value
    @forecasts.sum(&:value)
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
