class Refund < ApplicationRecord
  include HasFinancialQuarter
  has_one :comment,
    -> { where(commentable_type: "Refund") },
    foreign_key: :commentable_id,
    dependent: :destroy,
    autosave: true,
    class_name: "FlexibleComment"

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report
  validates_associated :comment

  validates :financial_quarter, presence: true
  validates :financial_year, presence: true
  validates :value, presence: true
end
