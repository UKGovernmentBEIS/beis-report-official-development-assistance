class Report < ApplicationRecord
  include PublicActivity::Common
  include HasFinancialQuarter

  EDITABLE_STATES = %w[active awaiting_changes]

  attr_readonly :financial_quarter, :financial_year

  validates_presence_of :state

  belongs_to :fund, -> { where(level: :fund) }, class_name: "Activity"
  belongs_to :organisation
  has_many :transactions
  has_many :forecasts
  has_many :historical_events

  validate :activity_must_be_a_fund
  validates :deadline, date_not_in_past: true, date_within_boundaries: true, on: :edit

  enum state: {
    inactive: "inactive",
    active: "active",
    submitted: "submitted",
    in_review: "in_review",
    awaiting_changes: "awaiting_changes",
    approved: "approved",
  }

  scope :in_historical_order, -> do
    clauses = [
      "reports.financial_year DESC NULLS LAST",
      "reports.financial_quarter DESC NULLS LAST",
      "reports.created_at DESC",
    ]

    order(clauses.join(", "))
  end

  scope :historically_up_to, ->(report) do
    historic_reports = where(financial_year: nil, financial_quarter: nil)

    quarter, year = report.financial_quarter, report.financial_year
    return historic_reports unless quarter && year

    created_at = report.created_at

    historic_reports
      .or(where("reports.financial_year < ?", year))
      .or(where(financial_year: year).where("reports.financial_quarter < ?", quarter))
      .or(where(financial_year: year, financial_quarter: quarter).where("reports.created_at <= ?", created_at))
  end

  scope :editable, -> do
    where(state: EDITABLE_STATES)
  end

  scope :for_activity, ->(activity) do
    where(fund_id: activity.associated_fund.id, organisation_id: activity.organisation_id)
  end

  def self.editable_for_activity(activity)
    editable.for_activity(activity).first
  end

  def initialize(attributes = nil)
    super(attributes)
    self.financial_quarter = FinancialQuarter.for_date(Date.today).to_i
    self.financial_year = FinancialYear.for_date(Date.today).to_i
  end

  def editable?
    state.in?(EDITABLE_STATES)
  end

  def activity_must_be_a_fund
    return unless fund.present?
    unless fund.fund?
      errors.add(:fund, I18n.t("activerecord.errors.models.report.attributes.fund.level"))
    end
  end

  def reportable_activities
    Activity.reportable.projects_and_third_party_projects_for_report(self).with_roda_identifier
  end

  def activities_created
    reportable_activities.where(created_at: financial_period)
  end
end
