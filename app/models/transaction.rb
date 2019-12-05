class Transaction < ApplicationRecord
  belongs_to :fund
  validates_presence_of :reference, :description, :transaction_type, :date, :currency, :value, :disbursement_channel
end
