class Commitment < ApplicationRecord
  include HasFinancialQuarter

  belongs_to :activity

  validates :value, presence: true
  validates :value, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 99_999_999_999.00
  }
  validates :transaction_date, presence: true
end
