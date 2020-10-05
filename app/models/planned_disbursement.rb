class PlannedDisbursement < ApplicationRecord
  include PublicActivity::Common
  PLANNED_DISBURSEMENT_BUDGET_TYPES = {"1": "original", "2": "revised"}

  strip_attributes only: :receiving_organisation_reference

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :planned_disbursement_type,
    :period_start_date,
    :currency,
    :value,
    :providing_organisation_name,
    :providing_organisation_type,
    :receiving_organisation_name,
    :receiving_organisation_type,
    :financial_quarter,
    :financial_year,
    :providing_organisation_reference
  validates :value, inclusion: {in: 0.01..99_999_999_999.00}

  def unknown_receiving_organisation_type?
    receiving_organisation_type == "0"
  end
end
