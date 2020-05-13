class PlannedDisbursement < ApplicationRecord
  belongs_to :parent_activity, class_name: "Activity"

  validates_presence_of :planned_disbursement_type,
    :period_start_date,
    :currency,
    :value,
    :providing_organisation_name,
    :providing_organisation_type,
    :receiving_organisation_name,
    :receiving_organisation_type
  validates :value, inclusion: {in: 0.01..99_999_999_999.00}
end
