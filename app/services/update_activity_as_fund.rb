class UpdateActivityAsFund
  attr_accessor :activity

  def initialize(activity:)
    self.activity = activity
  end

  def call
    activity.extending_organisation = service_owner

    activity.form_state = "parent"
    activity.level = :fund

    activity.accountable_organisation_name = "Department for Business, Energy and Industrial Strategy"
    activity.accountable_organisation_reference = "GB-GOV-13"
    activity.accountable_organisation_type = "10"

    activity.save(context: :parent_step)
    activity
  end

  private

  def service_owner
    Organisation.find_by_service_owner(true)
  end
end
