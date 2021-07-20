class ActivityDefaults
  class InvalidParentActivity < RuntimeError; end

  class InvalidDeliveryPartnerOrganisation < RuntimeError; end

  attr_reader :parent_activity, :delivery_partner_organisation

  def initialize(parent_activity:, delivery_partner_organisation:)
    @parent_activity = parent_activity
    @delivery_partner_organisation = delivery_partner_organisation

    check_params!
  end

  def call
    {
      parent_id: parent_activity.id,
      level: level,
      source_fund_code: source_fund_code,
      roda_identifier: roda_identifier,

      organisation_id: organisation.id,
      extending_organisation_id: extending_organisation.id,
      originating_report_id: originating_report&.id,

      form_state: form_state,
    }
  end

  private

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

    delivery_partner_organisation
  end

  def extending_organisation
    delivery_partner_organisation
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
    loop {
      roda_identifier = generate_roda_identifier
      break roda_identifier unless Activity.exists?(roda_identifier: roda_identifier)
    }
  end

  def generate_roda_identifier
    Activity::RodaIdentifierGenerator.new(
      parent_activity: parent_activity,
      extending_organisation: extending_organisation,
    ).generate
  end

  def check_params!
    raise InvalidParentActivity unless parent_activity.is_a?(Activity)
    raise InvalidParentActivity if parent_activity.third_party_project?

    raise InvalidDeliveryPartnerOrganisation unless delivery_partner_organisation.is_a?(Organisation)
    raise InvalidDeliveryPartnerOrganisation if delivery_partner_organisation.service_owner?
  end
end
