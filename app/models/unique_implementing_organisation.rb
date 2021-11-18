class UniqueImplementingOrganisation < ApplicationRecord
  validates :name, presence: true
  validates :organisation_type,
    presence: true,
    inclusion: {in: ->(_) { valid_organisation_types }, allow_blank: true}

  strip_attributes only: [:name, :reference]

  has_many :org_participations,
    -> { where(role: "Implementing").distinct },
    foreign_key: :organisation_id,
    inverse_of: :organisation
  has_many :activities, through: :org_participations

  scope :with_legacy_name, ->(name) do
    where(
      UniqueImplementingOrganisation
      .arel_table[:legacy_names]
      .contains([name])
    )
  end

  def self.find_matching(name)
    where(name: name.strip)
      .or(merge(with_legacy_name(name)))
      .first
  end

  private

  class << self
    private def valid_organisation_types
      organisations = Codelist.new(type: "organisation_type")
      organisations.map { |d| d["code"] }
    end
  end
end
