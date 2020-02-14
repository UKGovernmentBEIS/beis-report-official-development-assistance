class Transaction < ApplicationRecord
  belongs_to :activity
  validates_presence_of :reference,
    :description,
    :transaction_type,
    :date,
    :currency,
    :value,
    :disbursement_channel,
    :providing_organisation_name,
    :providing_organisation_type,
    :receiving_organisation_name,
    :receiving_organisation_type
  validates :value, inclusion: 1..99_999_999_999.00
  validates :date, date_within_boundaries: true
end
