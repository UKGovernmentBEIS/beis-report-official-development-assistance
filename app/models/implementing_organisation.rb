class ImplementingOrganisation < ApplicationRecord
  validates_presence_of :name, :organisation_type

  belongs_to :activity
end
