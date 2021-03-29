class Budget < ApplicationRecord
  include PublicActivity::Common

  IATI_TYPES = Codelist.new(type: "budget_type", source: "iati").hash_of_coded_names
  IATI_STATUSES = Codelist.new(type: "budget_status", source: "iati").hash_of_coded_names
  BUDGET_TYPES = Codelist.new(type: "budget_type", source: "beis").hash_of_coded_names
  DIRECT_BUDGET_TYPES = [BUDGET_TYPES["direct_newton_fund"], BUDGET_TYPES["direct_global_challenges_research_fund"]]

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :value,
    :currency,
    :financial_year
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validates :funding_type, inclusion: {in: BUDGET_TYPES.values}
  validate :direct_budget_type_must_match_source_fund, if: -> { DIRECT_BUDGET_TYPES.include?(funding_type) }

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

  private def direct_budget_type_must_match_source_fund
    return unless parent_activity&.source_fund_code.present?
    unless funding_type == parent_activity.source_fund_code
      errors.add(:funding_type, I18n.t("activerecord.errors.models.budget.attributes.funding_type.source_fund.#{parent_activity.source_fund_code}"))
    end
  end
end
