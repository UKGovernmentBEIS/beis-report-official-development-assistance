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

      organisation_id: organisation.id,
      extending_organisation_id: extending_organisation.id,

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

  def form_state
    Activity::FORM_STEPS.first.to_s
  end

  def check_params!
    raise InvalidParentActivity unless parent_activity.is_a?(Activity)
    raise InvalidParentActivity if parent_activity.third_party_project?

    raise InvalidDeliveryPartnerOrganisation unless delivery_partner_organisation.is_a?(Organisation)
    raise InvalidDeliveryPartnerOrganisation if delivery_partner_organisation.service_owner?
  end
end
