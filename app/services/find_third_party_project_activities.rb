class FindThirdPartyProjectActivities
  include Pundit

  attr_accessor :organisation, :user

  def initialize(organisation:, user:)
    @organisation = organisation
    @user = user
  end

  def call(eager_load_parent: true)
    eager_load_associations = [:organisation]
    eager_load_associations << :parent if eager_load_parent

    third_party_projects = ThirdPartyProjectPolicy::Scope.new(user, Activity.third_party_project)
      .resolve
      .includes(eager_load_associations)
      .order("created_at ASC")

    third_party_projects = if organisation.service_owner
      third_party_projects.all
    else
      third_party_projects.where(organisation_id: organisation.id)
    end
    third_party_projects
  end
end
