class UpdateActivityAsProgramme
  attr_accessor :activity, :parent_id

  def initialize(activity:, parent_id:)
    self.activity = activity
    self.parent_id = parent_id
  end

  def call
    activity.extending_organisation = service_owner

    set_parent_and_fund

    activity.form_state = "parent"
    activity.level = :programme

    activity.accountable_organisation_name = service_owner.name
    activity.accountable_organisation_reference = service_owner.iati_reference
    activity.accountable_organisation_type = service_owner.organisation_type

    activity.save(context: :parent_step)
    activity
  end

  def service_owner
    Organisation.find_by_service_owner(true)
  end

  private

  def fetch_source_fund_from_parent(parent)
    return if parent.nil?

    Fund.from_activity(parent)
  end

  def set_parent_and_fund
    parent = Activity.fund.find_by_id(parent_id)

    activity.parent = parent
    activity.source_fund = fetch_source_fund_from_parent(parent)
  end
end
