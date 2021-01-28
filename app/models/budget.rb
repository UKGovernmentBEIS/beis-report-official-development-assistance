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
    :currency,
    :funding_type
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :period_start_date, :period_end_date, date_within_boundaries: true
  validates :funding_type, inclusion: {in: ->(_) { valid_funding_type_codes }}

  validates_with BudgetDatesValidator, if: -> { period_start_date.present? && period_end_date.present? }

  BUDGET_TYPES = {"1": "original", "2": "updated"}
  STATUSES = {"1": "indicative", "2": "committed"}

  class << self
    def valid_funding_type_codes
      funding_types.values_for("code")
    end

    def funding_types
      Codelist.new(type: "fund_types", source: "beis")
    end
  end
end
