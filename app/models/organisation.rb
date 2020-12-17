class Organisation < ApplicationRecord
  include PublicActivity::Common

  strip_attributes only: [:iati_reference]
  has_many :users
  has_many :funds

  validates_presence_of :organisation_type, :language_code, :default_currency
  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false}
  validates :iati_reference,
    uniqueness: {case_sensitive: false},
    presence: true,
    format: {with: /\A[a-zA-Z]{2,}-[a-zA-Z]{3}-.+\z/, message: I18n.t("activerecord.errors.models.organisation.attributes.iati_reference.format")}

  scope :sorted_by_name, -> { order(name: :asc) }
  scope :delivery_partners, -> { sorted_by_name.where(service_owner: false) }

  def is_government?
    %w[10 11].include?(organisation_type)
  end
end
