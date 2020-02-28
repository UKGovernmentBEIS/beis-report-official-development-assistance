class Activity < ApplicationRecord
  validates :identifier, presence: true, if: :identifier_step?
  validates :title, :description, presence: true, if: :purpose_step?
  validates :sector, presence: true, if: :sector_step?
  validates :status, presence: true, if: :status_step?
  validates :recipient_region, presence: true, if: :region_step?
  validates :recipient_country, presence: true, if: :country_step?
  validates :flow, presence: true, if: :flow_step?
  validates :finance, presence: true, if: :finance_step?
  validates :aid_type, presence: true, if: :aid_type_step?
  validates :tied_status, presence: true, if: :tied_status_step?
  validates_uniqueness_of :identifier
  validates :planned_start_date, :planned_end_date, presence: true, if: :dates_step?
  validates :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date, date_within_boundaries: true
  validates :actual_start_date, :actual_end_date, date_not_in_future: true
  validates :extending_organisation_id, presence: true, on: :update_extending_organisation

  belongs_to :activity, optional: true
  has_many :activities, foreign_key: "activity_id"
  belongs_to :organisation
  belongs_to :extending_organisation, foreign_key: "extending_organisation_id", class_name: "Organisation", optional: true
  has_many :implementing_organisations

  enum level: {
    fund: "fund",
    programme: "programme",
    project: "project",
  }

  scope :funds, -> { where(level: :fund) }
  scope :programmes, -> { where(level: :programme) }

  private def identifier_step?
    wizard_status == "identifier" || wizard_complete?
  end

  private def purpose_step?
    wizard_status == "purpose" || wizard_complete?
  end

  private def sector_step?
    wizard_status == "sector" || wizard_complete?
  end

  private def status_step?
    wizard_status == "status" || wizard_complete?
  end

  private def dates_step?
    wizard_status == "dates" || wizard_complete?
  end

  def region_step?
    wizard_status == "region" || wizard_complete?
  end

  def country_step?
    wizard_status == "country" || wizard_complete?
  end

  private def flow_step?
    wizard_status == "flow" || wizard_complete?
  end

  private def finance_step?
    wizard_status == "finance" || wizard_complete?
  end

  private def aid_type_step?
    wizard_status == "aid_type" || wizard_complete?
  end

  private def tied_status_step?
    wizard_status == "tied_status" || wizard_complete?
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
    return [activity] if programme?
    return [activity.activity, activity] if project?
    []
  end
end
