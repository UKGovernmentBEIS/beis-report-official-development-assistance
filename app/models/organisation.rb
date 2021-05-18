class Organisation < ApplicationRecord
  include PublicActivity::Common

  SERVICE_OWNER_IATI_REFERENCE = "GB-GOV-13"

  strip_attributes only: [:iati_reference]
  has_many :users
  has_many :funds

  enum role: {
    delivery_partner: 0,
    service_owner: 99,
  }

  validates_presence_of :organisation_type, :language_code, :default_currency
  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false}
  validates :iati_reference,
    uniqueness: {case_sensitive: false},
    presence: true,
    format: {with: /\A[a-zA-Z]{2,}-[a-zA-Z]{3}-.+\z/, message: I18n.t("activerecord.errors.models.organisation.attributes.iati_reference.format")}
  validates :beis_organisation_reference,
    presence: true,
    uniqueness: {case_sensitive: false},
    format: {with: /\A[A-Z]{2,10}\z/, message: I18n.t("activerecord.errors.models.organisation.attributes.beis_organisation_reference.format")}

  scope :sorted_by_name, -> { order(name: :asc) }
  scope :delivery_partners, -> { sorted_by_name.where(role: "delivery_partner") }

  before_validation :ensure_beis_organisation_reference_is_uppercase

  def ensure_beis_organisation_reference_is_uppercase
    return unless beis_organisation_reference

    beis_organisation_reference.upcase!
  end

  def is_government?
    %w[10 11].include?(organisation_type)
  end

  def self.service_owner
    find_by(iati_reference: SERVICE_OWNER_IATI_REFERENCE)
  end
end
