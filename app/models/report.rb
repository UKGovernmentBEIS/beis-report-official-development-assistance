class Report < ApplicationRecord
  include HasFinancialQuarter

  EDITABLE_STATES = %w[active awaiting_changes]

  attr_readonly :financial_quarter, :financial_year

  validates_presence_of :state
  validates_presence_of :financial_quarter, :financial_year, on: :new
  validates :financial_quarter, inclusion: {in: 1..4}, if: :financial_quarter

  belongs_to :fund, -> { where(level: :fund) }, class_name: "Activity"
  belongs_to :organisation
  has_many :actuals
  has_many :forecasts
  has_many :historical_events
  has_many :refunds
  has_many :new_activities, class_name: "Activity", foreign_key: :originating_report_id
  has_many :comments

  validate :activity_must_be_a_fund
  validate :no_unapproved_reports_per_series, on: :new
  validates :deadline, date_not_in_past: true, date_within_boundaries: true, on: :edit

  enum state: {
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

  def editable?
    state.in?(EDITABLE_STATES)
  end

  def activity_must_be_a_fund
    return unless fund.present?
    unless fund.fund?
      errors.add(:fund, I18n.t("activerecord.errors.models.report.attributes.fund.level"))
    end
  end

  def no_unapproved_reports_per_series
    return unless fund.present? && organisation.present?

    unless Report.where(
      fund: fund,
      organisation: organisation,
    ).all?(&:approved?)
      errors.add(:base, I18n.t("activerecord.errors.models.report.unapproved_reports_html"))
    end
  end

  def reportable_activities
    Activity::ProjectsForReportFinder.new(report: self, scope: Activity.reportable).call.with_roda_identifier
  end

  def activities_updated
    Activity.where(id: historical_events.pluck(:activity_id))
  end

  def forecasts_for_reportable_activities
    ForecastOverview
      .new(reportable_activities.pluck(:id))
      .latest_values
      .where(report: self)
  end

  def summed_actuals
    actuals.sum(&:value)
  end

  def summed_refunds
    refunds.sum(&:value)
  end

  def summed_forecasts_for_reportable_activities
    forecasts_for_reportable_activities.sum(&:value)
  end
end
