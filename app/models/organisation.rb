class Organisation < ApplicationRecord
  has_many :users
  has_many :funds

  validates_presence_of :name, :organisation_type, :language_code, :default_currency
  validates :iati_reference, uniqueness: {case_sensitive: false}, presence: true

  scope :sorted_by_name, -> { order(name: :asc) }
end
