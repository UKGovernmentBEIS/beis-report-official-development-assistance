class Activity < ApplicationRecord
  belongs_to :hierarchy, polymorphic: true
  validates_presence_of :identifier
  validates_uniqueness_of :identifier

  attribute :recipient_region, :string, default: "998"
  attribute :flow, :string, default: "10"
  attribute :tied_status, :string, default: "5"

  def default_currency
    organisation.default_currency
  end

  def organisation
    hierarchy.organisation
  end
end
