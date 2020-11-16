class Activity < ApplicationRecord
  include PublicActivity::Common
  include CodelistHelper

  STANDARD_GRANT_FINANCE_CODE = "110"
  UNTIED_TIED_STATUS_CODE = "5"
  CAPITAL_SPEND_PERCENTAGE = 0

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
    :total_applications_and_awards_step,
    :programme_status_step,
    :geography_step,
    :region_step,
    :country_step,
    :requires_additional_benefitting_countries_step,
    :intended_beneficiaries_step,
    :gdi_step,
    :collaboration_type_step,
    :flow_step,
    :aid_type,
    :fstc_applies_step,
    :oda_eligibility_step,
  ]

  strip_attributes only: [:delivery_partner_identifier, :roda_identifier_fragment]

  validates :level, presence: true, on: :level_step
  validates :parent, presence: true, on: :parent_step, unless: proc { |activity| activity.fund? }
  validates :delivery_partner_identifier, presence: true, on: :identifier_step
  validates_with RodaIdentifierValidator, on: :roda_identifier_step
  validates :title, :description, presence: true, on: :purpose_step
  validates :sector_category, presence: true, on: :sector_category_step
  validates :sector, presence: true, on: :sector_step
  validates :call_present, inclusion: {in: [true, false]}, on: :call_present_step, if: :requires_call_dates?
  validates :total_applications, presence: true, on: :total_applications_and_awards_step, if: :call_present?
  validates :total_awards, presence: true, on: :total_applications_and_awards_step, if: :call_present?
  validates :programme_status, presence: true, on: :programme_status_step
  validates :geography, presence: true, on: :geography_step
  validates :recipient_region, presence: true, on: :region_step, if: :recipient_region?
  validates :recipient_country, presence: true, on: :country_step, if: :recipient_country?
  validates :requires_additional_benefitting_countries, inclusion: {in: [true, false]}, on: :requires_additional_benefitting_countries_step, if: :recipient_country?
  validates :intended_beneficiaries, presence: true, on: :intended_beneficiaries_step, if: :requires_intended_beneficiaries?
  validates :gdi, presence: true, on: :gdi_step
  validates :fstc_applies, inclusion: {in: [true, false]}, on: :fstc_applies_step
  validates :collaboration_type, presence: true, on: :collaboration_type_step, if: :requires_collaboration_type?
  validates :flow, presence: true, on: :flow_step
  validates :aid_type, presence: true, on: :aid_type_step
  validates :oda_eligibility, presence: true, on: :oda_eligibility_step

  validates :delivery_partner_identifier, uniqueness: {scope: :parent_id}, allow_nil: true
  validates :roda_identifier_compound, uniqueness: true, allow_nil: true
  validates :transparency_identifier, uniqueness: true, allow_nil: true
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

  has_many :comments

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

  enum oda_eligibility: {
    never_eligible: 0,
    eligible: 1,
    no_longer_eligible: 2,
  }

  scope :funds, -> { where(level: :fund) }
  scope :programmes, -> { where(level: :programme) }
  scope :publishable_to_iati, -> { where(form_state: :complete, publish_to_iati: true) }
  scope :with_roda_identifier, -> { where.not(roda_identifier_compound: nil) }

  scope :projects_and_third_party_projects_for_report, ->(report) {
    programmes = where(level: :programme, parent_id: report.fund_id)
    projects = where(level: :project, parent_id: programmes.pluck(:id))
    third_party_projects = where(level: :third_party_project, parent_id: projects.pluck(:id))

    for_organisation = where(organisation_id: report.organisation_id)

    for_organisation.merge(projects.or(third_party_projects))
  }

  def self.by_roda_identifier(identifier)
    find_by(roda_identifier_compound: identifier)
  end

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

  def capital_spend
    CAPITAL_SPEND_PERCENTAGE
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
    @parent_activities ||= ancestors.reverse
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
    when "programme" then "fund (level A)"
    when "project" then "programme (level B)"
    when "third_party_project" then "project (level C)"
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

  def roda_identifier
    roda_identifier_compound
  end

  def can_set_roda_identifier?
    identifier_fragments = roda_identifier_fragment_chain
    identifier_fragments[0..-2].all?(&:present?) && identifier_fragments.last.blank?
  end

  def cache_roda_identifier
    identifier_fragments = roda_identifier_fragment_chain
    return false unless identifier_fragments.all?(&:present?)

    compound = identifier_fragments[0..2].join("-")
    compound << identifier_fragments[3] if identifier_fragments.size == 4

    self.roda_identifier_compound = compound

    self.transparency_identifier ||= [
      reporting_organisation.iati_reference,
      compound.gsub(/[^a-z0-9-]+/i, "-"),
    ].join("-")

    true
  end

  def cache_roda_identifier!
    unless cache_roda_identifier
      raise TypeError, "Attempted to generate a RODA ID but some parent identifiers are blank"
    end
  end

  def roda_identifier_compound=(roda_identifier)
    if roda_identifier_compound.blank?
      super
    else
      raise TypeError, "Activity #{id} already has a compound RODA identifier"
    end
  end

  private def roda_identifier_fragment_chain
    activity_chain = parent_activities + [self]
    activity_chain.map(&:roda_identifier_fragment)
  end

  def iati_identifier
    if previous_identifier.present?
      previous_identifier
    else
      transparency_identifier
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

  def requires_intended_beneficiaries?
    recipient_region? || (recipient_country? && requires_additional_benefitting_countries?)
  end

  def comment_for_report(report_id:)
    comments.find_by(report_id: report_id)
  end

  def requires_collaboration_type?
    !ingested? && !fund?
  end
end
