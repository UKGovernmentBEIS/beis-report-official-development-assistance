class Transaction < ApplicationRecord
  belongs_to :fund
  validates_presence_of :reference, :description, :transaction_type, :date, :currency, :value, :disbursement_channel
  validates :value, inclusion: 1..99_999_999_999.00
end
