class Organisation < ApplicationRecord
  has_and_belongs_to_many :users
  validates_presence_of :name, :organisation_type, :language_code, :default_currency
end
