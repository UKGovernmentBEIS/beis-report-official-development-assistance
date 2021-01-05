class UpdateActivityAsProject
  attr_accessor :activity, :parent_id

  def initialize(activity:, parent_id:)
    self.activity = activity
    self.parent_id = parent_id
  end

  def call
    activity.reporting_organisation = reporting_organisation
    activity.extending_organisation = activity.organisation

    activity.parent = begin
                        Activity.programme.find(parent_id)
                      rescue ActiveRecord::RecordNotFound
                        nil
                      end

    activity.form_state = "parent"
    activity.level = :project

    activity.accountable_organisation_name = service_owner.name
    activity.accountable_organisation_reference = service_owner.iati_reference
    activity.accountable_organisation_type = service_owner.organisation_type

    activity.save(context: :parent_step)
    activity
  end

  private

  def service_owner
    Organisation.find_by_service_owner(true)
  end

  def reporting_organisation
    activity.organisation.is_government? ? service_owner : activity.organisation
  end
end
