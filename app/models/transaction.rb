class Transaction < ApplicationRecord
  include PublicActivity::Common

  TRANSACTION_TYPE_DISBURSEMENT = "3"
  DEFAULT_TRANSACTION_TYPE = TRANSACTION_TYPE_DISBURSEMENT

  strip_attributes only: [:providing_organisation_reference, :receiving_organisation_reference]

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :value,
    :financial_year,
    :receiving_organisation_name,
    :receiving_organisation_type
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :date, date_within_boundaries: true
  validates :financial_quarter, inclusion: {in: 1..4}

  before_validation :set_financial_quarter_from_date

  def financial_quarter_and_year
    if financial_year.present? && financial_quarter.present?
      FinancialQuarter.new(financial_year, financial_quarter).to_s
    end
  end

  private

  def set_financial_quarter_from_date
    has_date = date.present?
    has_quarter = (1..4).cover?(financial_quarter) && financial_year.present?

    if has_date && !has_quarter
      quarter = FinancialQuarter.for_date(date)
      self.financial_quarter = quarter.quarter
      self.financial_year = quarter.financial_year.start_year
    elsif has_quarter && !has_date
      quarter = FinancialQuarter.new(financial_year, financial_quarter)
      self.date = quarter.end_date
    end
  end
end
