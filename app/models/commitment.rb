class Commitment < ApplicationRecord
  include HasFinancialQuarter

  belongs_to :activity

  validates :value, :financial_quarter, :financial_year, presence: true
  validates :value, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 99_999_999_999.00
  }
  validates :financial_quarter, inclusion: {in: 1..4}
  validates :financial_year, numericality: {
    greater_than_or_equal_to: 2000,
    less_than_or_equal_to: 3000,
    only_integer: true
  }
end
