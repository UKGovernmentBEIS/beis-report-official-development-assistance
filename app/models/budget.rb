class Budget < ApplicationRecord
  include PublicActivity::Common

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :budget_type,
    :status,
    :period_start_date,
    :period_end_date,
    :value,
    :currency
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :period_start_date, :period_end_date, date_within_boundaries: true

  validates_with BudgetDatesValidator, if: -> { period_start_date.present? && period_end_date.present? }

  BUDGET_TYPES = {"1": "original", "2": "updated"}
  STATUSES = {"1": "indicative", "2": "committed"}
end
