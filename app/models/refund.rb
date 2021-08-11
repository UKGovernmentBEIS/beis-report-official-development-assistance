class Refund < ApplicationRecord
  include HasFinancialQuarter

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report

  validates :financial_quarter, presence: true
  validates :financial_year, presence: true
  validates :value, presence: true
end
