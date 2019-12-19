class Activity < ApplicationRecord
  belongs_to :hierarchy, polymorphic: true
  validates :identifier, presence: true, if: :identifier_step?
  validates :title, :description, presence: true, if: :purpose_step?
  validates :sector, presence: true, if: :sector_step?
  validates :status, presence: true, if: :status_step?
  validates :recipient_region, presence: true, if: :country_step?
  validates :flow, presence: true, if: :flow_step?
  validates :finance, presence: true, if: :finance_step?
  validates :aid_type, presence: true, if: :aid_type_step?
  validates :tied_status, presence: true, if: :tied_status_step?
  validates_uniqueness_of :identifier

  def identifier_step?
    wizard_status == "identifier"
  end

  def purpose_step?
    wizard_status == "purpose"
  end

  def sector_step?
    wizard_status == "sector"
  end

  def status_step?
    wizard_status == "status"
  end

  def country_step?
    wizard_status == "country"
  end

  def flow_step?
    wizard_status == "flow"
  end

  def finance_step?
    wizard_status == "finance"
  end

  def aid_type_step?
    wizard_status == "aid_type"
  end

  def tied_status_step?
    wizard_status == "tied_status"
  end

  def default_currency
    organisation.default_currency
  end

  def organisation
    hierarchy.organisation
  end
end
