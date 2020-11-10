class PlannedDisbursement < ApplicationRecord
  include PublicActivity::Common

  enum planned_disbursement_type: {original: "1", revised: "2"}

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true

  validate :only_one_original, on: :create

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :planned_disbursement_type,
    :period_start_date,
    :currency,
    :value,
    :providing_organisation_name,
    :providing_organisation_type,
    :providing_organisation_reference,
    :financial_quarter,
    :financial_year
  validates :value, inclusion: {in: 0.01..99_999_999_999.00}

  def only_one_original
    if PlannedDisbursement.find_by(financial_quarter: financial_quarter, financial_year: financial_year, parent_activity: parent_activity, planned_disbursement_type: :original).present?
      errors.add(:base, I18n.t("activerecord.errors.models.planned_disbursement.attributes.planned_disbursement_type.only_one_original", financial_quarter: financial_quarter, financial_year_start: financial_year, financial_year_end: financial_year + 1))
    end
  end
end
