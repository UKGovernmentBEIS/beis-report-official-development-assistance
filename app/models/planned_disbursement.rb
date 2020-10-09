class PlannedDisbursement < ApplicationRecord
  include PublicActivity::Common

  enum planned_disbursement_type: {original: "1", revised: "2"}

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :planned_disbursement_type,
    :period_start_date,
    :currency,
    :value,
    :providing_organisation_name,
    :providing_organisation_type,
    :providing_organisation_reference,
    :financial_quarter,
    :financial_year
  validates :value, inclusion: {in: 0.01..99_999_999_999.00}

  def unknown_receiving_organisation_type?
    receiving_organisation_type == "0"
  end
end
