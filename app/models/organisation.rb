class Organisation < ApplicationRecord
  SERVICE_OWNER_IATI_REFERENCE = "GB-GOV-13"

  strip_attributes only: [:iati_reference]
  has_many :users
  has_many :funds
  has_many :reports
  has_many :org_participations
  has_many :implementing_org_participations,
    -> { merge(OrgParticipation.implementing).distinct },
    class_name: "OrgParticipation"
  has_many :activities, through: :org_participations
  has_many :implemented_activities,
    through: :implementing_org_participations,
    class_name: "Activity",
    source: :activity

  enum role: {
    partner_organisation: 0,
    matched_effort_provider: 1,
    external_income_provider: 2,
    implementing_organisation: 3,
    service_owner: 99
  }

  validates_presence_of :organisation_type, :language_code, :default_currency
  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false}
  validates :iati_reference,
    uniqueness: {case_sensitive: false},
    presence: true,
    if: proc { |organisation| organisation.is_reporter? },
    format: {with: /\A[a-zA-Z]{2,}-[a-zA-Z]{3}-.+\z/, message: I18n.t("activerecord.errors.models.organisation.attributes.iati_reference.format")}
  validates :beis_organisation_reference, uniqueness: {case_sensitive: false}
  validates :beis_organisation_reference,
    presence: true,
    if: proc { |organisation| organisation.is_reporter? },
    format: {with: /\A[A-Z]{2,5}\z/, message: I18n.t("activerecord.errors.models.organisation.attributes.beis_organisation_reference.format")}

  scope :sorted_by_active, -> { order(active: :desc) }
  scope :sorted_by_name, -> { order(name: :asc) }
  scope :partner_organisations, -> { sorted_by_active.sorted_by_name.where(role: "partner_organisation") }
  scope :matched_effort_providers, -> { sorted_by_active.sorted_by_name.where(role: "matched_effort_provider") }
  scope :external_income_providers, -> { sorted_by_active.sorted_by_name.where(role: "external_income_provider") }
  scope :implementing, -> {
    where(<<~SQL
      organisations.id IN
      (
        (
          SELECT organisations.id
          FROM organisations
                 INNER JOIN org_participations
                 ON org_participations.organisation_id = organisations.id
                 WHERE org_participations.role = 3
        )
        UNION
        (
          SELECT organisations.id
          FROM organisations WHERE organisations.role = 3
        )
      )
    SQL
         )
      .sorted_by_active.sorted_by_name
  }
  scope :reporters, -> { sorted_by_name.where(role: ["partner_organisation", "service_owner"]) }
  scope :active, -> { where(active: true) }

  before_validation :ensure_beis_organisation_reference_is_uppercase

  def self.find_matching(name)
    where(name: name.strip)
      .or(where(
        Organisation
        .arel_table[:alternate_names]
        .contains([name])
      ))
      .first
  end

  def role
    # temp hack whilst we figure out how to handle moving role from Org to OrgParticipation
    return "implementing_organisation" unless read_attribute(:role)

    super
  end

  def ensure_beis_organisation_reference_is_uppercase
    return unless beis_organisation_reference

    beis_organisation_reference.upcase!
  end

  def is_government?
    %w[10 11].include?(organisation_type)
  end

  def is_reporter?
    service_owner? || partner_organisation?
  end

  def self.service_owner
    find_by(iati_reference: SERVICE_OWNER_IATI_REFERENCE)
  end
end
