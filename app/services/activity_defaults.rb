class ActivityDefaults
  class InvalidParentActivity < RuntimeError; end

  class InvalidPartnerOrganisation < RuntimeError; end

  attr_reader :parent_activity, :partner_organisation, :is_oda

  def initialize(parent_activity:, partner_organisation:, is_oda: nil)
    @parent_activity = parent_activity
    @partner_organisation = partner_organisation
    @is_oda = is_oda

    check_params!
  end

  def call
    is_not_oda? ? defaults.merge(non_oda_defaults) : defaults
  end

  private

  def defaults
    {
      parent_id: parent_activity.id,
      oda_eligibility: oda_eligibility,
      level: level,
      source_fund_code: source_fund_code,
      roda_identifier: roda_identifier,
      transparency_identifier: transparency_identifier,
      is_oda: is_oda?,
      organisation_id: organisation.id,
      extending_organisation_id: extending_organisation.id,
      originating_report_id: originating_report&.id,

      form_state: form_state
    }
  end

  def non_oda_defaults
    {
      transparency_identifier: nil,
      # oda_eligibility: Activity.oda_eligibilities[:never_eligible]
    }
  end

  def is_oda?
    @is_oda.nil? ? @parent_activity.is_oda : @is_oda
  end

  def is_not_oda?
    is_oda? == false # Must be explicitly false, nil indicates ODA.
  end

  def service_owner
    @_service_owner ||= Organisation.service_owner
  end

  def level
    parent_activity.child_level
  end

  def source_fund_code
    parent_activity.source_fund.id
  end

  def organisation
    return service_owner if level == "programme"

    partner_organisation
  end

  def extending_organisation
    partner_organisation
  end

  def originating_report
    Report.find_by(
      fund_id: parent_activity.associated_fund.id,
      organisation_id: organisation.id,
      state: Report::EDITABLE_STATES
    )
  end

  def form_state
    Activity::FORM_STEPS.first.to_s
  end

  def roda_identifier
    @roda_identifier ||= loop {
      roda_identifier = generate_roda_identifier
      break roda_identifier unless Activity.exists?(roda_identifier: roda_identifier)
    }
  end

  def generate_roda_identifier
    Activity::RodaIdentifierGenerator.new(
      parent_activity: parent_activity,
      extending_organisation: extending_organisation,
      is_non_oda: is_oda == false
    ).generate
  end

  def transparency_identifier
    [
      Organisation::SERVICE_OWNER_IATI_REFERENCE,
      roda_identifier
    ].join("-")
  end

  def check_params!
    raise InvalidParentActivity unless parent_activity.is_a?(Activity)
    raise InvalidParentActivity if parent_activity.third_party_project?

    raise InvalidPartnerOrganisation unless partner_organisation.is_a?(Organisation)
    raise InvalidPartnerOrganisation if partner_organisation.service_owner?
  end
end
