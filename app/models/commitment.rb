class Commitment < ApplicationRecord
  belongs_to :activity

  validates :value, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 99_999_999_999.00,
  }
end
