class Organisation < ApplicationRecord
  has_many :users
  has_many :funds

  validates_presence_of :name, :organisation_type, :language_code, :default_currency
  validates :iati_reference, uniqueness: {case_sensitive: false}, presence: true

  scope :sorted_by_name, -> { order(name: :asc) }
  scope :delivery_partners, -> { sorted_by_name.where(service_owner: false) }

  def is_government_organisation?
    %w[10 11].include?(organisation_type)
  end
end
