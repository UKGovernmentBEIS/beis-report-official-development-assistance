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
  validates :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date, date_within_boundaries: true

  def identifier_step?
    %w[identifier complete].include?(wizard_status)
  end

  def purpose_step?
    %w[purpose complete].include?(wizard_status)
  end

  def sector_step?
    %w[sector complete].include?(wizard_status)
  end

  def status_step?
    %w[status complete].include?(wizard_status)
  end

  def country_step?
    %w[country complete].include?(wizard_status)
  end

  def flow_step?
    %w[flow complete].include?(wizard_status)
  end

  def finance_step?
    %w[finance complete].include?(wizard_status)
  end

  def aid_type_step?
    %w[aid_type complete].include?(wizard_status)
  end

  def tied_status_step?
    %w[tied_status complete].include?(wizard_status)
  end

  def default_currency
    organisation.default_currency
  end

  def organisation
    hierarchy.organisation
  end
end
