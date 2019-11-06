class Organisation < ApplicationRecord
  validates_presence_of :name, :organisation_type, :language_code, :default_currency
end
