class OrgParticipation < ApplicationRecord
  belongs_to :activity
  belongs_to :organisation

  attribute :role, :string, default: "implementing"

  enum role: {
    partner_organisation: 0,
    matched_effort_provider: 1,
    external_income_provider: 2,
    implementing: 3,
    service_owner: 99
  }

  scope :implementing, -> { where(role: :implementing) }

  validate :organisation_is_active, if: :implementing?, on: :create

  private

  def organisation_is_active
    unless organisation&.active
      errors.add(:base, I18n.t("activerecord.errors.models.org_participation.attributes.organisation.inactive"))
    end
  end

  # At present this join model is only linking orgs with the "Implementing" role
  # to their "Activity" but we plan to use this for all type of Organisation, e.g.
  #
  #  Activity#has_one
  #    :partner_organisation
  #    through: :extending_org_participation
  #
  # Activity#has_one
  #   :extending_org_participations,
  #   -> { where("org_participations.role = 'Extending'") },
  #   class_name: "OrgParticipation"
  #
  # In this way there will be one table of Organisations and one table of
  # OrgParticipations, with OrPgarticipation#role distinguishing the types
  # of particpation defined by IATI:
  #
  # 1. *Funding*: The government or organisation which
  #    provides funds to the activity.
  #
  # 2. *Accountable*: An organisation responsible for
  #     oversight of the activity and its outcomes
  #
  # 3. *Extending*: An organisation that manages the budget
  #    and direction of an activity on behalf of the funding
  #    organisation
  #
  # 4. *Implementing*: The organisation that physically carries
  #    out the activity or intervention.
end
