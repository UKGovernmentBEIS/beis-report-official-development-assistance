class ActivityDefaults
  attr_reader :parent_activity, :delivery_partner_organisation

  def initialize(parent_activity:, delivery_partner_organisation:)
    @parent_activity = parent_activity
    @delivery_partner_organisation = delivery_partner_organisation
  end

  def call
    {
      parent_id: parent_activity.id,
      level: level,
      source_fund_code: source_fund_code,

      organisation_id: organisation.id,
      extending_organisation_id: extending_organisation.id,
      reporting_organisation_id: reporting_organisation.id,

      accountable_organisation_name: accountable_organisation.name,
      accountable_organisation_reference: accountable_organisation.iati_reference,
      accountable_organisation_type: accountable_organisation.organisation_type,

      form_state: form_state,
    }
  end

  private

  def service_owner
    @_service_owner ||= Organisation.find_by(service_owner: true)
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

  def reporting_organisation
    service_owner
  end

  def accountable_organisation
    return service_owner if level == "programme"

    delivery_partner_organisation.is_government? ? service_owner : delivery_partner_organisation
  end

  def form_state
    parent_step_index = Activity::FORM_STEPS.index(:parent)

    Activity::FORM_STEPS[parent_step_index + 1].to_s
  end
end
