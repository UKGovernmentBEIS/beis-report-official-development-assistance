class ImplementingOrganisation < ApplicationRecord
  validates :name, presence: true
  validates :organisation_type, presence: true, inclusion: {in: ->(_) { valid_organisation_types }, allow_blank: true}

  strip_attributes only: [:name, :reference]

  belongs_to :activity

  private

  class << self
    private def valid_organisation_types
      organisations = Codelist.new(type: "organisation_type")
      organisations.map { |d| d["code"] }
    end
  end
end
