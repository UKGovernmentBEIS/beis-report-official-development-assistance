class Activity < ApplicationRecord
  belongs_to :hierarchy, polymorphic: true
  validates_presence_of :identifier
  validates_uniqueness_of :identifier

  def default_currency
    organisation.default_currency
  end

  def organisation
    hierarchy.organisation
  end
end
