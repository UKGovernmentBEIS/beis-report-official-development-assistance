class Activity < ApplicationRecord
  include CodelistHelper

  STANDARD_GRANT_FINANCE_CODE = "110"
  UNTIED_TIED_STATUS_CODE = "5"
  CAPITAL_SPEND_PERCENTAGE = 0
  DEFAULT_FLOW_TYPE = "10"

  POLICY_MARKER_CODES = Codelist.new(type: "policy_significance", source: "beis").hash_of_integer_coded_names
  DESERTIFICATION_POLICY_MARKER_CODES = Codelist.new(type: "policy_significance_desertification", source: "beis").hash_of_integer_coded_names

  FORM_STEPS = [
    :is_oda,
    :identifier,
    :linked_activity,
    :purpose,
    :objectives,
    :sector_category,
    :sector,
    :call_present,
    :call_dates,
    :total_applications_and_awards,
    :programme_status,
    :country_partner_organisations,
    :dates,
    :ispf_partner_countries,
    :benefitting_countries,
    :gdi,
    :aid_type,
    :collaboration_type,
    :sustainable_development_goals,
    :ispf_theme,
    :fund_pillar,
    :fstc_applies,
    :policy_markers,
    :covid19_related,
    :gcrf_strategic_area,
    :gcrf_challenge_area,
    :channel_of_delivery_code,
    :oda_eligibility,
    :oda_eligibility_lead,
    :uk_po_named_contact,
    :implementing_organisation
  ]

  VALIDATION_STEPS = [
    :is_oda_step,
    :identifier_step,
    :roda_identifier_step,
    :purpose_step,
    :objectives_step,
    :sector_category_step,
    :sector_step,
    :call_present_step,
    :call_dates_step,
    :dates_step,
    :ispf_partner_countries_step,
    :total_applications_and_awards_step,
    :programme_status_step,
    :country_partner_organisations_step,
    :gdi_step,
    :aid_type_step,
    :collaboration_type_step,
    :sustainable_development_goals_step,
    :ispf_theme_step,
    :fund_pillar_step,
    :fstc_applies_step,
    :policy_markers_step,
    :covid19_related_step,
    :gcrf_challenge_area_step,
    :channel_of_delivery_code_step,
    :oda_eligibility_step,
    :oda_eligibility_lead_step,
    :uk_po_named_contact_step,
    :implementing_organisation_step
  ]

  FORM_STATE_VALIDATION_LIST = FORM_STEPS.map(&:to_s).push("complete")

  before_validation :strip_control_characters_from_fields!

  strip_attributes only: [:partner_organisation_identifier]

  attr_reader :implementing_organisation_id

  validates :level, presence: true
  validates :parent, absence: true, if: proc { |activity| activity.fund? }
  validates :parent, presence: true, unless: proc { |activity| activity.fund? }
  validates_with OrganisationValidator
  validates :partner_organisation_identifier, presence: true, on: :identifier_step, if: :is_project?
  validates :title, :description, presence: true, on: :purpose_step
  validates :objectives, presence: true, on: :objectives_step, if: :requires_objectives?
  validates :sector_category, presence: true, on: :sector_category_step
  validates :sector, presence: true, on: :sector_step
  validates :call_present, inclusion: {in: [true, false]}, on: :call_present_step, if: :requires_call_dates?
  validates :total_applications, presence: true, on: :total_applications_and_awards_step, if: :call_present?
  validates :total_awards, presence: true, on: :total_applications_and_awards_step, if: :call_present?
  validates :programme_status, presence: true, on: :programme_status_step
  validates :country_partner_organisations, presence: true, on: :country_partner_organisations_step, if: :requires_country_partner_organisations?
  validates :gdi, presence: true, on: :gdi_step, if: :requires_gdi?
  validates :fstc_applies, inclusion: {in: [true, false]}, on: :fstc_applies_step, if: :requires_fstc_applies?
  validates :covid19_related, presence: true, on: :covid19_related_step, if: :requires_covid19_related?
  validates :collaboration_type, presence: true, on: :collaboration_type_step, if: :requires_collaboration_type?
  validates :fund_pillar, presence: true, on: :fund_pillar_step, if: :is_newton_funded?
  validates :sdg_1, presence: true, on: :sustainable_development_goals_step, if: :sdgs_apply?
  validates :aid_type, presence: true, on: :aid_type_step, if: :requires_aid_type?
  validates :ispf_theme, presence: true, on: :ispf_theme_step, if: :is_ispf_funded?
  validates :ispf_partner_countries, presence: true, on: :ispf_partner_countries_step, if: :is_ispf_funded?
  validates :policy_marker_gender, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_climate_change_adaptation, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_climate_change_mitigation, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_biodiversity, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_desertification, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_disability, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_disaster_risk_reduction, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :policy_marker_nutrition, presence: true, on: :policy_markers_step, if: :requires_policy_markers?
  validates :gcrf_challenge_area, presence: true, on: :gcrf_challenge_area_step, if: :is_gcrf_funded?
  validates :gcrf_strategic_area, presence: true, length: {maximum: 2}, on: :gcrf_strategic_area_step, if: :is_gcrf_funded?
  validates :oda_eligibility, presence: true, on: :oda_eligibility_step, if: :requires_oda_eligibility?
  validates :oda_eligibility_lead, presence: true, on: :oda_eligibility_lead_step, if: :requires_oda_eligibility_lead?
  validates :uk_po_named_contact, presence: true, on: :uk_po_named_contact_step, if: :is_project?
  validates_with ChannelOfDeliveryCodeValidator, on: :channel_of_delivery_code_step, if: :requires_channel_of_delivery_code?

  validates :partner_organisation_identifier, uniqueness: {scope: :parent_id}, allow_nil: true
  validates :roda_identifier, uniqueness: true, allow_nil: true
  validates :transparency_identifier, uniqueness: true, allow_nil: true
  validates :planned_start_date, presence: {message: I18n.t("activerecord.errors.models.activity.attributes.dates")}, on: :dates_step, unless: proc { |a| a.actual_start_date.present? }
  validates :actual_start_date, presence: {message: I18n.t("activerecord.errors.models.activity.attributes.dates")}, on: :dates_step, unless: proc { |a| a.planned_start_date.present? }
  validates :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date, date_within_boundaries: true
  validates :actual_start_date, :actual_end_date, date_not_in_future: true
  validates :planned_end_date, end_date_after_start_date: true, if: :planned_start_date?
  validates :call_open_date, presence: true, on: :call_dates_step, if: :call_present?
  validates :call_close_date, presence: true, on: :call_dates_step, if: :call_present?
  validates :form_state, inclusion: {in: FORM_STATE_VALIDATION_LIST}

  validates :is_oda, inclusion: {in: [true, false]}, on: :is_oda_step, if: :requires_is_oda?

  acts_as_tree
  belongs_to :parent, optional: true, class_name: :Activity, foreign_key: "parent_id"

  has_many :child_activities, foreign_key: "parent_id", class_name: "Activity"
  belongs_to :originating_report, class_name: "Report", optional: true
  belongs_to :organisation
  belongs_to :extending_organisation, foreign_key: "extending_organisation_id", class_name: "Organisation", optional: true
  has_many :implementing_org_participations,
    -> { merge(OrgParticipation.implementing) },
    ### ^ this is messing up the use of << on new
    class_name: "OrgParticipation",
    dependent: :destroy
  has_many :implementing_organisations,
    -> { distinct },
    through: :implementing_org_participations,
    source: :organisation

  has_many :budgets, foreign_key: "parent_activity_id"
  has_many :actuals, foreign_key: "parent_activity_id"
  has_many :refunds, foreign_key: "parent_activity_id"
  has_many :adjustments, foreign_key: "parent_activity_id"

  has_many :source_transfers, foreign_key: "source_id", class_name: "OutgoingTransfer"
  has_many :destination_transfers, foreign_key: "destination_id", class_name: "OutgoingTransfer"

  has_many :comments, foreign_key: "commentable_id", as: :commentable
  has_many :comments_on_self_and_transactions, ->(activity) { unscope(:where).for_activity(activity) }, class_name: "Comment", foreign_key: "commentable_id"
  has_many :matched_efforts
  has_many :external_incomes
  has_many :historical_events, dependent: :destroy

  has_one :commitment, dependent: :destroy

  has_many :reports,
    ->(activity) { unscope(:where).for_activity(activity).in_historical_order }

  belongs_to :linked_activity, optional: true, class_name: "Activity"
  after_save :ensure_linked_activity_reciprocity

  enum level: {
    fund: "fund",
    programme: "programme",
    project: "project",
    third_party_project: "third_party_project"
  }

  enum geography: {
    recipient_region: "Recipient region",
    recipient_country: "Recipient country"
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
    paused: 12
  }

  NON_CURRENT_PROGRAMME_STATUSES = ["completed", "stopped", "cancelled"]
  UNREPORTABLE_PROGRAMME_STATUSES = NON_CURRENT_PROGRAMME_STATUSES + ["paused"]

  enum policy_marker_gender: POLICY_MARKER_CODES, _prefix: :gender

  enum policy_marker_climate_change_adaptation: POLICY_MARKER_CODES, _prefix: :climate_change_adaptation

  enum policy_marker_climate_change_mitigation: POLICY_MARKER_CODES, _prefix: :climate_change_mitigation

  enum policy_marker_biodiversity: POLICY_MARKER_CODES, _prefix: :biodiversity

  enum policy_marker_desertification: DESERTIFICATION_POLICY_MARKER_CODES, _prefix: :desertification

  enum policy_marker_disability: POLICY_MARKER_CODES, _prefix: :disability

  enum policy_marker_disaster_risk_reduction: POLICY_MARKER_CODES, _prefix: :disaster_risk_reduction

  enum policy_marker_nutrition: POLICY_MARKER_CODES, _prefix: :nutrition

  enum oda_eligibility: {
    never_eligible: 0,
    eligible: 1,
    no_longer_eligible: 2
  }

  scope :programmes, -> { where(level: :programme) }
  scope :publishable_to_iati, -> { where(form_state: :complete, publish_to_iati: true) }
  scope :with_roda_identifier, -> { where.not(roda_identifier: nil) }

  scope :current, -> {
                    where.not(programme_status: NON_CURRENT_PROGRAMME_STATUSES).or(where(programme_status: nil))
                  }

  scope :reportable, -> {
    where(oda_eligibility: "eligible").where.not(programme_status: UNREPORTABLE_PROGRAMME_STATUSES)
  }

  scope :historic, -> {
    where(programme_status: ["completed", "stopped", "cancelled"])
  }

  scope :not_ispf, -> { where.not(source_fund_code: Fund.by_short_name("ISPF")) }

  def self.new_child(parent_activity:, partner_organisation:, is_oda: nil, &block)
    attributes = ActivityDefaults.new(
      parent_activity: parent_activity,
      partner_organisation: partner_organisation,
      is_oda: is_oda
    ).call

    new(attributes, &block).tap do |new_activity|
      if new_activity.programme?
        new_activity.implementing_org_participations << OrgParticipation.new(
          organisation: partner_organisation,
          role: "implementing",
          activity: new_activity
        )
      end
    end
  end

  def self.by_roda_identifier(identifier)
    find_by(roda_identifier: identifier)
  end

  def latest_report
    reports.first
  end

  def descendants
    sql = <<~SQL
      WITH RECURSIVE descendants AS (
        SELECT activities.*
            FROM activities
            WHERE parent_id = ?
        UNION
            SELECT activities.*
                FROM activities
                INNER JOIN descendants ON descendants.id = activities.parent_id
      ) SELECT * FROM descendants
    SQL
    Activity.find_by_sql([sql, id])
  end

  def total_spend(financial_quarter = nil)
    entity_types = %w[actuals adjustments refunds]
    b = binding

    entity_types.each do |entity_type|
      model = entity_type.singularize.humanize.constantize

      b.local_variable_set(entity_type, send(:own_and_descendants_associates, model))
    end

    if financial_quarter
      entity_types.each do |entity_type|
        b.local_variable_set(
          entity_type,
          b.local_variable_get(entity_type).where(
            financial_year: financial_quarter.financial_year.to_i,
            financial_quarter: financial_quarter.to_i
          )
        )
      end
    end

    entity_types.map { |entity_type| b.local_variable_get(entity_type).sum(:value) }.sum
  end

  def total_budget
    Budget.direct.where(parent_activity_id: id).sum(:value)
  end

  def future_forecasts
    activity_ids = descendants.pluck(:id).append(id)
    ForecastOverview.new(activity_ids)
      .latest_values
      .select { |forecast| forecast.later_period_than?(latest_report) }
  end

  def total_forecasted
    future_forecasts.sum(&:value)
  end

  def own_and_descendants_associates(model)
    activity_ids = descendants.pluck(:id).append(id)

    model.where(parent_activity_id: activity_ids)
  end

  def reportable_actuals_for_level
    if programme?
      spend_by_financial_quarter(own_and_descendants_associates(Actual).order("date DESC"))
    else
      actuals.order("date DESC")
    end
  end

  def reportable_forecasts_for_level
    return latest_forecasts unless programme?

    activity_ids = descendants.pluck(:id).append(id)
    forecasts = ForecastOverview.new(activity_ids).latest_values.group_by(&:own_financial_quarter)
    quarters = forecasts.keys.sort.reverse

    quarters.map do |quarter|
      ForecastAggregate.new(quarter, forecasts[quarter])
    end
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

  def has_extending_organisation?
    extending_organisation.present?
  end

  def has_implementing_organisations?
    implementing_organisations.any?
  end

  def parent_activities
    @parent_activities ||= ancestors.reverse
  end

  def source_fund=(fund)
    self.source_fund_code = fund&.id
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
    (third_party_project? && !organisation.is_government?) ? organisation : service_owner
  end

  def funding_organisation
    return nil if fund?

    service_owner
  end

  def accountable_organisation
    return service_owner if fund? || programme?

    extending_organisation.is_government? ? service_owner : extending_organisation
  end

  def accountable_organisation_name
    accountable_organisation.name
  end

  def accountable_organisation_name=(_)
    # NO OP
  end

  def accountable_organisation_type
    accountable_organisation.organisation_type
  end

  def accountable_organisation_type=(_)
    # NO OP
  end

  def accountable_organisation_reference
    accountable_organisation.iati_reference
  end

  def accountable_organisation_reference=(_)
    # NO OP
  end

  def service_owner
    Organisation.service_owner
  end

  def benefitting_region
    @benefitting_region ||= begin
      return nil unless benefitting_countries.present?
      BenefittingCountry.region_from_country_codes(benefitting_countries)
    end
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
    if previous_identifier.present?
      previous_identifier
    else
      transparency_identifier
    end
  end

  def actual_total_for_report_financial_quarter(report:)
    Actual::Overview.new(report: report, include_adjustments: true).value_for_report_quarter(self)
  end

  def forecasted_total_for_report_financial_quarter(report:)
    @forecasted_total_for_report_financial_quarter ||= ForecastOverview.new(self).snapshot(report).value_for_report_quarter
  end

  def variance_for_report_financial_quarter(report:)
    @variance_for_report_financial_quarter ||= actual_total_for_report_financial_quarter(report: report) - forecasted_total_for_report_financial_quarter(report: report)
  end

  def latest_forecasts
    ForecastOverview.new(self).latest_values
  end

  def requires_objectives?
    !fund? && !is_non_oda?
  end

  def requires_call_dates?
    is_project?
  end

  def requires_benefitting_countries?
    !is_non_oda?
  end

  def requires_gdi?
    !fund? && !is_non_oda?
  end

  def requires_aid_type?
    !is_non_oda?
  end

  def requires_covid19_related?
    [
      programme? && is_ispf_funded?,
      is_non_oda_project?
    ].none?
  end

  def requires_oda_eligibility?
    !is_non_oda?
  end

  def requires_oda_eligibility_lead?
    is_project? && !is_non_oda?
  end

  def comments_for_report(report_id:)
    comments_on_self_and_transactions.where(report_id: report_id)
  end

  def requires_collaboration_type?
    [
      fund?,
      programme? && is_ispf_funded?,
      is_non_oda_project?
    ].none?
  end

  def requires_channel_of_delivery_code?
    is_project? && !is_non_oda?
  end

  def requires_fstc_applies?
    [
      programme? && is_ispf_funded?,
      is_non_oda_project?
    ].none?
  end

  def requires_policy_markers?
    is_project? && !is_non_oda?
  end

  def is_project?
    project? || third_party_project?
  end

  def is_gcrf_funded?
    !fund? && source_fund.present? && source_fund.gcrf?
  end

  def is_newton_funded?
    !fund? && source_fund.present? && source_fund.newton?
  end

  def is_ispf_funded?
    !fund? && source_fund.present? && source_fund.ispf?
  end

  def is_non_oda?
    is_oda == false
  end

  def requires_is_oda?
    programme? && is_ispf_funded?
  end

  def requires_country_partner_organisations?
    is_newton_funded? && programme?
  end

  def requires_implementing_organisation?
    third_party_project? && is_ispf_funded? && !has_implementing_organisations?
  end

  def iati_status
    return if programme_status.blank?

    iati_status_from_programme_status(programme_status)
  end

  def historic?
    programme_status.in?(["completed", "stopped", "cancelled"])
  end

  def ensure_linked_activity_reciprocity
    return unless saved_change_to_attribute?(:linked_activity_id)

    formerly_linked_activity_id = saved_change_to_attribute(:linked_activity_id).first
    if formerly_linked_activity_id && (formerly_linked_activity = Activity.find_by(id: formerly_linked_activity_id)).present?
      # we do not want to propagate this, because it would nullify self.linked_activity_id
      formerly_linked_activity.update_columns(linked_activity_id: nil)
    end

    if linked_activity.present?
      # we do want to propagate this change, in case the newly linked activity was previously linked to another
      linked_activity.linked_activity = self
      linked_activity.save
    end
  end

  def linkable_activities
    return [] unless is_ispf_funded?
    return [] if is_project? && parent.linked_activity.nil?

    if programme?
      parent.child_activities.where(is_oda: !is_oda, extending_organisation: extending_organisation, linked_activity_id: [nil, id])
    else
      parent.linked_activity.child_activities.where(linked_activity_id: [nil, id])
    end
  end

  def linked_child_activities
    child_activities.where.not(linked_activity_id: nil)
  end

  def self.hierarchically_grouped_projects
    activities = all.to_a
    projects = activities.select(&:project?).sort_by { |a| a.roda_identifier.to_s }
    third_party_projects = activities.select(&:third_party_project?).group_by(&:parent_id)

    grouped_projects = []
    projects.each do |project|
      grouped_projects << project
      grouped_projects += third_party_projects.fetch(project.id, []).sort_by { |a| a.roda_identifier.to_s }
    end
    grouped_projects
  end

  # we delete control characters (the first unprintable bit of ASCII)
  # that aren't tab (\x09), linefeed (\x0a) or carriage return (\x0d)
  # https://www.w3.org/International/questions/qa-controls#support
  XML_1_0_ILLEGAL_CHARACTERS = /[\x00-\x08\x0b\x0c\x0e-\x1f]/.freeze

  private

  def strip_control_characters(string)
    return if string.nil?

    string.gsub(XML_1_0_ILLEGAL_CHARACTERS, "")
  end

  def strip_control_characters_from_fields!
    text_fields = Activity.columns.select { |col| %i[string text].include?(col.type) && !col.array }.map(&:name)

    text_fields.each do |attr|
      stripped_value = strip_control_characters(send(attr))
      send("#{attr}=", stripped_value)
    end
  end

  def spend_by_financial_quarter(reportable_actuals)
    reportable_actuals.group_by(&:own_financial_quarter).map do |financial_quarter, actuals|
      Actual.new(date: financial_quarter.end_date, value: actuals.sum(&:value), transaction_type: Transaction::DEFAULT_TRANSACTION_TYPE)
    end
  end

  def is_non_oda_project?
    is_project? && is_non_oda?
  end
end
