class Forecast < ApplicationRecord
  include HasFinancialQuarter

  DIRECT_ACCESS_WARNING = "The Forecast model should not be accessed \
directly; please use the ForecastHistory and ForecastOverview \
services to create forecasts. See doc/forecasts-and-versioning.md for more information."

  default_scope do
    raise TypeError, DIRECT_ACCESS_WARNING
  end

  attr_readonly :parent_activity_id,
    :financial_quarter,
    :financial_year,
    :report_id

  enum :forecast_type, {original: "1", revised: "2"}

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :forecast_type,
    :period_start_date,
    :currency,
    :value,
    :providing_organisation_name,
    :providing_organisation_type,
    :providing_organisation_reference,
    :financial_quarter,
    :financial_year
end
