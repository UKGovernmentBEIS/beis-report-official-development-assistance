class Budget < ApplicationRecord
  belongs_to :activity

  validates_presence_of :budget_type,
    :status,
    :period_start_date,
    :period_end_date,
    :value,
    :currency
  validates :value, inclusion: 1..99_999_999_999.00
  validates :period_start_date, :period_end_date, date_within_boundaries: true

  BUDGET_TYPES = {original: "original", updated: "updated"}
  STATUSES = {indicative: "indicative", committed: "committed"}
end
