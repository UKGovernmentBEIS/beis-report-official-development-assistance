class Transaction < ApplicationRecord
  include PublicActivity::Common

  strip_attributes only: [:providing_organisation_reference, :receiving_organisation_reference]

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :value,
    :date,
    :receiving_organisation_name,
    :receiving_organisation_type
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :date, date_not_in_future: true, date_within_boundaries: true
end
