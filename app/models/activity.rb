class Activity < ApplicationRecord
  belongs_to :hierarchy, polymorphic: true
  validates_presence_of :identifier
  validates_uniqueness_of :identifier

  def set_hierarchy_defaults
    case hierarchy.class.name
    when "Fund" then set_fund_defaults
    end
  end

  def default_currency
    organisation.default_currency
  end

  def organisation
    hierarchy.organisation
  end

  private

  def set_fund_defaults
    self.recipient_region = "998"
    self.flow = "10"
    self.tied_status = "5"
  end
end
