class Transaction < ApplicationRecord
  belongs_to :fund
  validates_presence_of :reference, :description, :transaction_type, :date, :currency, :value, :disbursement_channel
  belongs_to :provider, foreign_key: :provider_id, class_name: "Organisation"
  belongs_to :receiver, foreign_key: :receiver_id, class_name: "Organisation"
  validates :value, inclusion: 1..99_999_999_999.00
end
