class AdjustmentDetail < ApplicationRecord
  belongs_to :user
  belongs_to :adjustment

  validates :adjustment_type, inclusion: {in: %w[Actual Refund]}
  validates :user, presence: true
end
