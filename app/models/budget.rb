class Budget < ApplicationRecord
  audited only: %i[value], on: %i[create update]

  IATI_TYPES = Codelist.new(type: "budget_type", source: "iati").hash_of_coded_names
  IATI_STATUSES = Codelist.new(type: "budget_status", source: "iati").hash_of_coded_names

  enum budget_type: {
    direct: 0,
    other_official: 1
  }

  belongs_to :parent_activity, class_name: "Activity"
  belongs_to :report, optional: true
  belongs_to :providing_organisation, class_name: "Organisation", optional: true

  before_validation :infer_and_assign_providing_org_attrs

  validates_presence_of :report, unless: -> { parent_activity&.organisation&.service_owner? }
  validates_presence_of :value,
    :currency,
    :financial_year,
    :budget_type
  validates :value, numericality: {other_than: 0, less_than_or_equal_to: 99_999_999_999.00}
  validate :ensure_value_changed, on: :update

  with_options if: -> { direct? } do |direct_budget|
    direct_budget.validate :direct_budget_providing_org_must_be_beis
    direct_budget.validates :providing_organisation_id, presence: true
  end

  with_options if: -> { other_official? } do |external_budget|
    external_budget.validates :providing_organisation_name, presence: true
    external_budget.validates :providing_organisation_type, presence: true
  end

  def financial_year
    return nil if self[:financial_year].nil?

    FinancialYear.new(self[:financial_year])
  end

  def period_start_date
    financial_year&.start_date
  end

  def period_end_date
    financial_year&.end_date
  end

  def iati_type
    return IATI_TYPES.fetch("original") if original?

    IATI_TYPES.fetch("revised")
  end

  def iati_status
    IATI_STATUSES.fetch("indicative")
  end

  def original_revision
    audits.find_by(action: "create").revision
  end

  def any_update_audits?
    audits.updates.any?
  end

  private def original?
    return audits.none? || audits.last.version == 1 if live?

    audit_version == 1
  end

  private def live?
    # audit_version is only available on revisions. If the object
    # is not a revision, we can determine that it is the live Budget.
    audit_version.nil?
  end

  private def ensure_value_changed
    errors.add(:value, :not_changed) if audit_comment.present? && !value_changed?
  end

  private def direct_budget_providing_org_must_be_beis
    errors.add(:providing_organisation_name, "Providing organisation for direct funding must be BEIS!") unless providing_organisation.service_owner?
  end

  private def infer_and_assign_providing_org_attrs
    if direct?
      self.providing_organisation_id = Organisation.service_owner.id
      self.providing_organisation_name = nil
      self.providing_organisation_type = nil
      self.providing_organisation_reference = nil
    else
      self.providing_organisation_id = nil
    end
  end
end
