class FindThirdPartyProjectActivities
  include Pundit

  attr_accessor :organisation, :user

  def initialize(organisation:, user:)
    @organisation = organisation
    @user = user
  end

  def call
    third_party_projects = ThirdPartyProjectPolicy::Scope.new(user, Activity.third_party_project)
      .resolve
      .includes(:organisation, :extending_organisation, :implementing_organisations, :budgets, :parent)
      .order("created_at ASC")

    if organisation.service_owner?
      third_party_projects.all
    else
      third_party_projects.where(organisation_id: organisation.id)
    end
  end
end
