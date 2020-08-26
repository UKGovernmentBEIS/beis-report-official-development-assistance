class Activity < ApplicationRecord
  include PublicActivity::Common
  include CodelistHelper

  STANDARD_GRANT_FINANCE_CODE = "110"
  UNTIED_TIED_STATUS_CODE = "5"

  VALIDATION_STEPS = [
    :level_step,
    :parent_step,
    :identifier_step,
    :roda_identifier_step,
    :purpose_step,
    :sector_category_step,
    :sector_step,
    :call_present_step,
    :call_dates_step,
    :programme_status_step,
    :geography_step,
    :region_step,
    :country_step,
    :flow_step,
    :aid_type,
  ]

  strip_attributes only: [:delivery_partner_identifier, :roda_identifier_fragment]

  validates :level, presence: true, on: :level_step
  validates :parent, presence: true, on: :parent_step, unless: proc { |activity| activity.fund? }
  validates :delivery_partner_identifier, presence: true, on: :identifier_step
  validates :title, :description, presence: true, on: :purpose_step
  validates :sector_category, presence: true, on: :sector_category_step
  validates :sector, presence: true, on: :sector_step
  validates :call_present, inclusion: {in: [true, false]}, on: :call_present_step, if: :requires_call_dates?
  validates :programme_status, presence: true, on: :programme_status_step
  validates :geography, presence: true, on: :geography_step
  validates :recipient_region, presence: true, on: :region_step, if: :recipient_region?
  validates :recipient_country, presence: true, on: :country_step, if: :recipient_country?
  validates :flow, presence: true, on: :flow_step
  validates :aid_type, presence: true, on: :aid_type_step

  validates :delivery_partner_identifier, uniqueness: {scope: :parent_id}, allow_nil: true
  validates :planned_start_date, presence: {message: I18n.t("activerecord.errors.models.activity.attributes.dates")}, on: :dates_step, unless: proc { |a| a.actual_start_date.present? }
  validates :actual_start_date, presence: {message: I18n.t("activerecord.errors.models.activity.attributes.dates")}, on: :dates_step, unless: proc { |a| a.planned_start_date.present? }
  validates :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date, date_within_boundaries: true
  validates :actual_start_date, :actual_end_date, date_not_in_future: true
  validates :extending_organisation_id, presence: true, on: :update_extending_organisation
  validates :call_open_date, presence: true, on: :call_dates_step, if: :call_present?
  validates :call_close_date, presence: true, on: :call_dates_step, if: :call_present?

  acts_as_tree
  belongs_to :parent, optional: true, class_name: :Activity, foreign_key: "parent_id"

  has_many :child_activities, foreign_key: "parent_id", class_name: "Activity"
  belongs_to :organisation
  belongs_to :extending_organisation, foreign_key: "extending_organisation_id", class_name: "Organisation", optional: true
  has_many :implementing_organisations
  belongs_to :reporting_organisation, foreign_key: "reporting_organisation_id", class_name: "Organisation"

  has_many :budgets, foreign_key: "parent_activity_id"
  has_many :transactions, foreign_key: "parent_activity_id"
  has_many :planned_disbursements, foreign_key: "parent_activity_id"

  enum level: {
    fund: "fund",
    programme: "programme",
    project: "project",
    third_party_project: "third_party_project",
  }

  enum geography: {
    recipient_region: "Recipient region",
    recipient_country: "Recipient country",
  }

  scope :funds, -> { where(level: :fund) }
  scope :programmes, -> { where(level: :programme) }
  scope :publishable_to_iati, -> { where(form_state: :complete, publish_to_iati: true) }

  def valid?(context = nil)
    context = VALIDATION_STEPS if context.nil? && form_steps_completed?
    super(context)
  end

  def form_steps_completed?
    form_state == "complete"
  end

  def finance
    STANDARD_GRANT_FINANCE_CODE
  end

  def tied_status
    UNTIED_TIED_STATUS_CODE
  end

  def default_currency
    organisation.default_currency
  end

  def has_funding_organisation?
    funding_organisation_reference.present? &&
      funding_organisation_name.present? &&
      funding_organisation_type.present?
  end

  def has_accountable_organisation?
    accountable_organisation_reference.present? &&
      accountable_organisation_name.present? &&
      accountable_organisation_type.present?
  end

  def has_extending_organisation?
    extending_organisation.present?
  end

  def has_implementing_organisations?
    implementing_organisations.any?
  end

  def parent_activities
    ancestors.reverse
  end

  def associated_fund
    return self if fund?
    parent_activities.detect(&:fund?)
  end

  def providing_organisation
    return organisation if third_party_project? && !organisation.is_government?
    Organisation.find_by(service_owner: true)
  end

  def parent_level
    case level
    when "fund" then nil
    when "programme" then "fund"
    when "project" then "programme"
    when "third_party_project" then "project"
    end
  end

  def child_level
    case level
    when "fund" then "programme"
    when "programme" then "project"
    when "project" then "third_party_project"
    when "third_party_project" then raise "no level below third_party_project"
    end
  end

  def iati_identifier
    parent_activities.each_with_object([reporting_organisation.iati_reference]) { |parent, parent_identifiers|
      parent_identifiers << parent.delivery_partner_identifier
    }.push(delivery_partner_identifier).join("-")
  end

  def cache_roda_identifier
    activity_chain = parent_activities + [self]
    identifier_fragments = activity_chain.map(&:roda_identifier_fragment)
    return false unless identifier_fragments.all?(&:present?)

    compound = identifier_fragments[0..2].join("-")
    compound << identifier_fragments[3] if identifier_fragments.size == 4

    self.roda_identifier_compound = compound
    true
  end

  def cache_roda_identifier!
    unless cache_roda_identifier
      raise TypeError, "Attempted to generate a RODA ID but some parent identifiers are blank"
    end
  end

  def actual_total_for_report_financial_quarter(report:)
    @actual_total_for_report_financial_quarter ||= transactions.where(report: report, date: report.created_at.all_quarter).sum(:value)
  end

  def forecasted_total_for_report_financial_quarter(report:)
    @forecasted_total_for_report_financial_quarter ||= forecasted_total_for_date_range(range: report.created_at.all_quarter)
  end

  def variance_for_report_financial_quarter(report:)
    @variance_for_report_financial_quarter ||= actual_total_for_report_financial_quarter(report: report) - forecasted_total_for_report_financial_quarter(report: report)
  end

  def requires_call_dates?
    !ingested? && (project? || third_party_project?)
  end

  def forecasted_total_for_date_range(range:)
    planned_disbursements.where(period_start_date: range).sum(:value)
  end
end
