class FindProjectActivities
  include Pundit

  attr_accessor :organisation, :user

  def initialize(organisation:, user:)
    @organisation = organisation
    @user = user
  end

  def call(eager_load_parent: true)
    eager_load_associations = [:organisation]
    eager_load_associations << :parent if eager_load_parent

    projects = ProjectPolicy::Scope.new(user, Activity.project)
      .resolve
      .includes(eager_load_associations)
      .order("created_at ASC")

    projects = if organisation.service_owner
      projects.all
    else
      projects.where(organisation_id: organisation.id)
    end
    projects
  end
end
