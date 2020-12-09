class Report < ApplicationRecord
  include PublicActivity::Common

  attr_readonly :financial_quarter, :financial_year

  validates_presence_of :description, on: [:edit, :activate]
  validates_presence_of :state

  belongs_to :fund, -> { where(level: :fund) }, class_name: "Activity"
  belongs_to :organisation
  has_many :transactions
  has_many :planned_disbursements

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
    where(state: [:active, :awaiting_changes])
  end

  scope :for_activity, ->(activity) do
    where(fund_id: activity.associated_fund.id, organisation_id: activity.organisation_id)
  end

  def self.editable_for_activity(activity)
    editable.for_activity(activity).first
  end

  def initialize(attributes = nil)
    super(attributes)
    self.financial_quarter = current_financial_quarter
    self.financial_year = current_financial_year
  end

  def activity_must_be_a_fund
    return unless fund.present?
    unless fund.fund?
      errors.add(:fund, I18n.t("activerecord.errors.models.report.attributes.fund.level"))
    end
  end

  def reportable_activities
    Activity.projects_and_third_party_projects_for_report(self).with_roda_identifier
  end

  def next_four_financial_quarters
    quarter, year = current_financial_quarter, current_financial_year

    (0..3).map do |increment|
      next_quarter = quarter + increment
      [
        (next_quarter % 4) + 1,
        next_quarter >= 4 ? year + 1 : year,
      ]
    end
  end

  private def current_financial_quarter
    case Date.today.month
    when 4, 5, 6
      1
    when 7, 8, 9
      2
    when 10, 11, 12
      3
    when 1, 2, 3
      4
    end
  end

  private def current_financial_year
    year = Date.today.year
    return year - 1 if current_financial_quarter == 4
    year
  end
end
