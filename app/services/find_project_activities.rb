class FindProjectActivities
  include Pundit

  attr_accessor :organisation, :current_user

  def initialize(organisation:, current_user:)
    @organisation = organisation
    @current_user = current_user
  end

  def call
    projects = policy_scope(Activity.project, policy_scope_class: ProjectPolicy::Scope)
      .includes(:organisation, :parent)
      .order("created_at ASC")
    projects = if organisation.service_owner
      projects.all
    else
      projects.where(organisation_id: organisation.id)
    end
    projects
  end
end
