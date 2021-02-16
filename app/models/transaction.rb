class Transaction < ApplicationRecord
  include PublicActivity::Common

  TRANSACTION_TYPE_DISBURSEMENT = "3"
  DEFAULT_TRANSACTION_TYPE = TRANSACTION_TYPE_DISBURSEMENT

  strip_attributes only: [:providing_organisation_reference, :receiving_organisation_reference]

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :value,
    :date,
    :receiving_organisation_name,
    :receiving_organisation_type
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :date, date_not_in_future: true, date_within_boundaries: true

  before_save :set_financial_quarter_from_date

  def financial_quarter_and_year
    return nil if date.blank?

    FinancialQuarter.for_date(date).to_s
  end

  private

  def set_financial_quarter_from_date
    return if date.blank?
    return if financial_quarter.present? && financial_year.present?

    financial_quarter = FinancialQuarter.for_date(date)
    self.financial_quarter = financial_quarter.quarter
    self.financial_year = financial_quarter.financial_year.start_year
  end
end
