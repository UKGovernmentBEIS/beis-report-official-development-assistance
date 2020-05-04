class Activity < ApplicationRecord
  include PublicActivity::Common

  STANDARD_GRANT_FINANCE_CODE = "110"
  UNTIED_TIED_STATUS_CODE = "5"

  VALIDATION_STEPS = [
    :identifier_step,
    :purpose_step,
    :sector_step,
    :status_step,
    :geography_step,
    :region_step,
    :country_step,
    :flow_step,
    :aid_type,
  ]

  validates :identifier, presence: true, on: :identifier_step
  validates :title, :description, presence: true, on: :purpose_step
  validates :sector, presence: true, on: :sector_step
  validates :status, presence: true, on: :status_step
  validates :geography, presence: true, on: :geography_step
  validates :recipient_region, presence: true, on: :region_step, if: :recipient_region?
  validates :recipient_country, presence: true, on: :country_step, if: :recipient_country?
  validates :flow, presence: true, on: :flow_step
  validates :aid_type, presence: true, on: :aid_type_step

  validates_uniqueness_of :identifier
  validates :planned_start_date, :planned_end_date, presence: true, on: :dates_step
  validates :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date, date_within_boundaries: true
  validates :actual_start_date, :actual_end_date, date_not_in_future: true
  validates :extending_organisation_id, presence: true, on: :update_extending_organisation

  belongs_to :activity, optional: true
  has_many :child_activities, foreign_key: "activity_id", class_name: "Activity"
  belongs_to :organisation
  belongs_to :extending_organisation, foreign_key: "extending_organisation_id", class_name: "Organisation", optional: true
  has_many :implementing_organisations
  belongs_to :reporting_organisation, foreign_key: "reporting_organisation_id", class_name: "Organisation"

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

  def valid?(context = nil)
    context = VALIDATION_STEPS if context.nil? && final?
    super(context)
  end

  def final?
    wizard_complete?
  end

  def finance
    STANDARD_GRANT_FINANCE_CODE
  end

  def tied_status
    UNTIED_TIED_STATUS_CODE
  end

  def wizard_complete?
    wizard_status == "complete"
  end

  def default_currency
    organisation.default_currency
  end

  def parent_activity
    return if activity_id.nil?
    Activity.find(activity_id)
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
    return [parent_activity] if programme?
    return [parent_activity.parent_activity, parent_activity] if project?
    return [parent_activity.parent_activity.parent_activity, parent_activity.parent_activity, parent_activity] if third_party_project?
    []
  end
end
