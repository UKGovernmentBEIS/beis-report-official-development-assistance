class Transaction < ApplicationRecord
  include HasFinancialQuarter

  TRANSACTION_TYPE_DISBURSEMENT = "3"
  DEFAULT_TRANSACTION_TYPE = TRANSACTION_TYPE_DISBURSEMENT

  strip_attributes only: [:providing_organisation_reference, :receiving_organisation_reference]

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true
  has_many :historical_events, dependent: :destroy, as: :trackable

  validates_with TransactionOrganisationValidator
  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :value, :financial_year
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :date, date_within_boundaries: true
  validates :financial_quarter, inclusion: {in: 1..4}

  attribute :currency, :string, default: "GBP"
  attribute :transaction_type, :string, default: Transaction::TRANSACTION_TYPE_DISBURSEMENT

  before_validation :set_financial_quarter_from_date

  scope :with_adjustment_details, -> { joins("LEFT OUTER JOIN adjustment_details ON transactions.id = adjustment_details.adjustment_id") }

  private

  def set_financial_quarter_from_date
    has_date = date.present?
    has_quarter = (1..4).cover?(financial_quarter) && financial_year.present?

    if has_date && !has_quarter
      quarter = FinancialQuarter.for_date(date)
      self.financial_quarter = quarter.quarter
      self.financial_year = quarter.financial_year.start_year
    elsif has_quarter && !has_date
      self.date = own_financial_quarter.end_date
    end
  end
end
