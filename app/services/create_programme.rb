class CreateProgramme
  attr_accessor :organisation_id, :source_fund_id

  def initialize(organisation_id:, source_fund_id:)
    self.organisation_id = organisation_id
    self.source_fund_id = source_fund_id
  end

  def call
    source_fund = Fund.new(source_fund_id)
    parent = source_fund.activity

    activity = Activity.new(
      level: :programme,
      parent: parent,
      source_fund: source_fund,

      organisation: service_owner,
      reporting_organisation: organisation,
      extending_organisation: service_owner, # FIXME

      accountable_organisation_name: service_owner.name,
      accountable_organisation_reference: service_owner.iati_reference,
      accountable_organisation_type: service_owner.organisation_type,

      form_state: "identifier"
    )

    activity.save!(context: [:level_step, :parent_step])
    activity
  end

  private

  def organisation
    @_organisation ||= Organisation.find(organisation_id)
  end

  def service_owner
    @_service_owner ||= Organisation.find_by_service_owner(true)
  end
end
