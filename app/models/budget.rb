class Budget < ApplicationRecord
  include PublicActivity::Common

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :value,
    :currency,
    :funding_type,
    :financial_year
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :funding_type, inclusion: {in: ->(_) { valid_funding_type_codes }}
  validate :funding_type_must_match_source_fund, unless: -> { parent_activity&.source_fund_code.blank? }

  IATI_TYPES = Codelist.new(type: "budget_type", source: "iati").hash_of_coded_names
  IATI_STATUSES = Codelist.new(type: "budget_status", source: "iati").hash_of_coded_names

  def financial_year
    return nil if self[:financial_year].nil?

    @financial_year ||= FinancialYear.new(self[:financial_year])
  end

  def period_start_date
    financial_year&.start_date
  end

  def period_end_date
    financial_year&.end_date
  end

  def iati_type
    IATI_TYPES.fetch("original")
  end

  def iati_status
    IATI_STATUSES.fetch("committed")
  end

  private def funding_type_must_match_source_fund
    return unless parent_activity.present?
    unless funding_type == parent_activity.source_fund_code
      errors.add(:funding_type, I18n.t("activerecord.errors.models.budget.attributes.funding_type.source_fund.#{parent_activity.source_fund_code}"))
    end
  end

  class << self
    def valid_funding_type_codes
      funding_types.values_for("code")
    end

    def funding_types
      Codelist.new(type: "fund_types", source: "beis")
    end
  end
end
