class FindThirdPartyProjectActivities
  include Pundit

  attr_accessor :organisation, :current_user

  def initialize(organisation:, current_user:)
    @organisation = organisation
    @current_user = current_user
  end

  def call
    third_party_projects = policy_scope(Activity.third_party_project, policy_scope_class: ThirdPartyProjectPolicy::Scope)
      .includes(:organisation, :parent)
      .order("created_at ASC")
    third_party_projects = if organisation.service_owner
      third_party_projects.all
    else
      third_party_projects.where(organisation_id: organisation.id)
    end
    third_party_projects
  end
end
