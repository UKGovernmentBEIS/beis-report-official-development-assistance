class ImplementingOrganisation < ApplicationRecord
  validates_presence_of :name, :organisation_type

  strip_attributes only: [:reference]

  belongs_to :activity
end
