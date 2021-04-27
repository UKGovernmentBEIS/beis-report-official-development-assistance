class FindProjectActivities
  include Pundit

  attr_accessor :organisation, :user

  def initialize(organisation:, user:)
    @organisation = organisation
    @user = user
  end

  def call
    projects = ProjectPolicy::Scope.new(user, Activity.project)
      .resolve
      .includes(:organisation, :extending_organisation, :implementing_organisations, :budgets, :parent)
      .order("created_at ASC")

    projects = if organisation.service_owner
      projects.all
    else
      projects.where(organisation_id: organisation.id)
    end
    projects
  end
end
