class Activity < ApplicationRecord
  include PublicActivity::Common
  include CodelistHelper

  STANDARD_GRANT_FINANCE_CODE = "110"
  UNTIED_TIED_STATUS_CODE = "5"
  CAPITAL_SPEND_PERCENTAGE = 0
  DEFAULT_FLOW_TYPE = "10"

  POLICY_MARKER_CODES = {
    not_targeted: 0,
    significant_objective: 1,
    principal_objective: 2,
    principal_objective_and_in_support: 3,
    not_assessed: 1000,
  }

  FORM_STEPS = [
    :blank,
    :level,
    :parent,
    :identifier,
    :roda_identifier,
    :purpose,
    :objectives,
    :sector_category,
    :sector,
    :call_present,
    :call_dates,
    :total_applications_and_awards,
    :programme_status,
    :country_delivery_partners,
    :dates,
    :geography,
    :region,
    :country,
    :requires_additional_benefitting_countries,
    :intended_beneficiaries,
    :gdi,
    :collaboration_type,
    :sustainable_development_goals,
    :fund_pillar,
    :aid_type,
    :fstc_applies,
    :policy_markers,
    :covid19_related,
    :gcrf_challenge_area,
    :channel_of_delivery_code,
    :oda_eligibility,
    :oda_eligibility_lead,
    :uk_dp_named_contact,
  ]

  VALIDATION_STEPS = [
    :level_step,
    :parent_step,
    :identifier_step,
    :roda_identifier_step,
    :purpose_step,
    :objectives_step,
    :sector_category_step,
    :sector_step,
    :call_present_step,
    :call_dates_step,
    :total_applications_and_awards_step,
    :programme_status_step,
    :country_delivery_partners_step,
    :geography_step,
    :region_step,
    :country_step,
    :requires_additional_benefitting_countries_step,
    :intended_beneficiaries_step,
    :gdi_step,
    :collaboration_type_step,
    :sustainable_development_goals_step,
    :aid_type_step,
    :fund_pillar_step,
    :fstc_applies_step,
    :policy_markers_step,
    :covid19_related_step,
    :gcrf_challenge_area_step,
    :channel_of_delivery_code_step,
    :oda_eligibility_step,
    :oda_eligibility_lead_step,
    :uk_dp_named_contact_step,
  ]

  FORM_STATE_VALIDATION_LIST = FORM_STEPS.map(&:to_s).push("complete", "recipient_country", "recipient_region")

  strip_attributes only: [:delivery_partner_identifier, :roda_identifier_fragment]

  validates :level, presence: true, on: :level_step
  validates :parent, presence: true, on: :parent_step, unless: proc { |activity| activity.fund? }
  validates :delivery_partner_identifier, presence: true, on: :identifier_step
  validates_with RodaIdentifierValidator, on: :roda_identifier_step
  validates :title, :description, presence: true, on: :purpose_step
  validates :objectives, presence: true, on: :objectives_step, unless: proc { |activity| activity.fund? }
  validates :sector_category, presence: true, on: :sector_category_step
  validates :sector, presence: true, on: :sector_step
  validates :call_present, inclusion: {in: [true, false]}, on: :call_present_step, if: :requires_call_dates?
  validates :total_applications, presence: true, on: :total_applications_and_awards_step, if: :call_present?
  validates :total_awards, presence: true, on: :total_applications_and_awards_step, if: :call_present?
  validates :programme_status, presence: true, on: :programme_status_step
  validates :country_delivery_partners, presence: true, on: :country_delivery_partners_step, if: :requires_country_delivery_partners?
  validates :geography, presence: true, on: :geography_step
  validates :recipient_region, presence: true, on: :region_step, if: :recipient_region?
  validates :recipient_country, presence: true, on: :country_step, if: :recipient_country?
  validates :requires_additional_benefitting_countries, inclusion: {in: [true, false], message: I18n.t("activerecord.errors.models.activity.attributes.requires_additional_benefitting_countries.blank")}, on: :requires_additional_benefitting_countries_step
  validates :intended_beneficiaries, presence: true, length: {maximum: 10}, on: :intended_beneficiaries_step, if: :requires_additional_benefitting_countries?
  validates :gdi, presence: true, on: :gdi_step
  validates :fstc_applies, inclusion: {in: [true, false]}, on: :fstc_applies_step
  validates :covid19_related, presence: true, on: :covid19_related_step
  validates :collaboration_type, presence: true, on: :collaboration_type_step, if: :requires_collaboration_type?
  validates :fund_pillar, presence: true, on: :fund_pillar_step, if: :is_newton_funded?
  validates :sdg_1, presence: true, on: :sustainable_development_goals_step, if: :sdgs_apply?
  validates :aid_type, presence: true, on: :aid_type_step
  validates :policy_marker_gender, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_climate_change_adaptation, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_climate_change_mitigation, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_biodiversity, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_desertification, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_disability, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_disaster_risk_reduction, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_nutrition, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :gcrf_challenge_area, presence: true, on: :gcrf_challenge_area_step, if: :is_gcrf_funded?
  validates :oda_eligibility, presence: true, on: :oda_eligibility_step
  validates :oda_eligibility_lead, presence: true, on: :oda_eligibility_lead_step, if: :is_project?
  validates :uk_dp_named_contact, presence: true, on: :uk_dp_named_contact_step, if: :is_project?
  validates_with ChannelOfDeliveryCodeValidator, on: :channel_of_delivery_code_step, if: :is_project?

  validates :delivery_partner_identifier, uniqueness: {scope: :parent_id}, allow_nil: true
  validates :roda_identifier_compound, uniqueness: true, allow_nil: true
  validates :transparency_identifier, uniqueness: true, allow_nil: true
  validates :planned_start_date, presence: {message: I18n.t("activerecord.errors.models.activity.attributes.dates")}, on: :dates_step, unless: proc { |a| a.actual_start_date.present? }
  validates :actual_start_date, presence: {message: I18n.t("activerecord.errors.models.activity.attributes.dates")}, on: :dates_step, unless: proc { |a| a.planned_start_date.present? }
  validates :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date, date_within_boundaries: true
  validates :actual_start_date, :actual_end_date, date_not_in_future: true
  validates :planned_end_date, end_date_after_start_date: true, if: :planned_start_date?
  validates :extending_organisation_id, presence: true, on: :update_extending_organisation
  validates :call_open_date, presence: true, on: :call_dates_step, if: :call_present?
  validates :call_close_date, presence: true, on: :call_dates_step, if: :call_present?
  validates :form_state, inclusion: {in: FORM_STATE_VALIDATION_LIST}, allow_nil: true

  acts_as_tree
  belongs_to :parent, optional: true, class_name: :Activity, foreign_key: "parent_id"

  has_many :child_activities, foreign_key: "parent_id", class_name: "Activity"
  belongs_to :organisation
  belongs_to :extending_organisation, foreign_key: "extending_organisation_id", class_name: "Organisation", optional: true
  has_many :implementing_organisations, dependent: :destroy
  validates_associated :implementing_organisations
  belongs_to :reporting_organisation, foreign_key: "reporting_organisation_id", class_name: "Organisation"

  has_many :budgets, foreign_key: "parent_activity_id"
  has_many :transactions, foreign_key: "parent_activity_id"

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

  enum programme_status: {
    delivery: 1,
    planned: 2,
    agreement_in_place: 3,
    open_for_applications: 4,
    review: 5,
    decided: 6,
    spend_in_progress: 7,
    finalisation: 8,
    completed: 9,
    stopped: 10,
    cancelled: 11,
    paused: 12,
  }

  enum policy_marker_gender: POLICY_MARKER_CODES, _prefix: :gender

  enum policy_marker_climate_change_adaptation: POLICY_MARKER_CODES, _prefix: :climate_change_adaptation

  enum policy_marker_climate_change_mitigation: POLICY_MARKER_CODES, _prefix: :climate_change_mitigation

  enum policy_marker_biodiversity: POLICY_MARKER_CODES, _prefix: :biodiversity

  enum policy_marker_desertification: POLICY_MARKER_CODES, _prefix: :desertification

  enum policy_marker_disability: POLICY_MARKER_CODES, _prefix: :disability

  enum policy_marker_disaster_risk_reduction: POLICY_MARKER_CODES, _prefix: :disaster_risk_reduction

  enum policy_marker_nutrition: POLICY_MARKER_CODES, _prefix: :nutrition

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

  scope :current, -> {
                    where.not(programme_status: ["completed", "stopped", "cancelled"]).or(where(programme_status: nil))
                  }

  scope :historic, -> {
    where(programme_status: ["completed", "stopped", "cancelled"])
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

  def flow
    DEFAULT_FLOW_TYPE
  end

  def default_currency
    organisation.default_currency
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

  def source_fund
    @source_fund ||= if source_fund_code.present?
      Fund.new(source_fund_code)
    end
  end

  def associated_fund
    return self if fund?
    parent_activities.detect(&:fund?)
  end

  def providing_organisation
    third_party_project? && !organisation.is_government? ? organisation : service_owner
  end

  def funding_organisation
    return nil if fund?

    service_owner
  end

  def service_owner
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
    transactions.where(report: report, date: report.created_at.all_quarter).sum(:value)
  end

  def forecasted_total_for_report_financial_quarter(report:)
    @forecasted_total_for_report_financial_quarter ||= PlannedDisbursementOverview.new(self).snapshot(report).value_for_report_quarter
  end

  def variance_for_report_financial_quarter(report:)
    @variance_for_report_financial_quarter ||= actual_total_for_report_financial_quarter(report: report) - forecasted_total_for_report_financial_quarter(report: report)
  end

  def latest_planned_disbursements
    PlannedDisbursementOverview.new(self).latest_values
  end

  def requires_call_dates?
    !ingested? && is_project?
  end

  def comment_for_report(report_id:)
    comments.find_by(report_id: report_id)
  end

  def requires_collaboration_type?
    !ingested? && !fund?
  end

  def requires_policy_markers?
    !ingested? && is_project?
  end

  def is_project?
    project? || third_party_project?
  end

  def is_gcrf_funded?
    parent.present? && associated_fund.roda_identifier_fragment == "GCRF"
  end

  def is_newton_funded?
    parent.present? && associated_fund.roda_identifier_fragment == "NF"
  end

  def requires_country_delivery_partners?
    is_newton_funded? && programme?
  end

  def iati_status
    return if programme_status.blank?

    iati_status_from_programme_status(programme_status)
  end

  def self.hierarchically_grouped_projects
    activities = all.to_a
    projects = activities.select(&:project?).sort_by { |a| a.roda_identifier_fragment.to_s }
    third_party_projects = activities.select(&:third_party_project?).group_by(&:parent_id)

    grouped_projects = []
    projects.each do |project|
      grouped_projects << project
      grouped_projects += third_party_projects.fetch(project.id, []).sort_by { |a| a.roda_identifier_fragment.to_s }
    end
    grouped_projects
  end
end
