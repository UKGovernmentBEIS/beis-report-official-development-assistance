class Budget < ApplicationRecord
  include PublicActivity::Model
  tracked owner: proc { |controller, _model| controller.current_user }

  belongs_to :parent_activity, class_name: "Activity"

  validates_presence_of :budget_type,
    :status,
    :period_start_date,
    :period_end_date,
    :value,
    :currency
  validates :value, inclusion: 1..99_999_999_999.00
  validates :period_start_date, :period_end_date, date_within_boundaries: true

  validates_with BudgetDatesValidator, if: -> { period_start_date.present? && period_end_date.present? }

  BUDGET_TYPES = {original: "original", updated: "updated"}
  STATUSES = {indicative: "indicative", committed: "committed"}
end
