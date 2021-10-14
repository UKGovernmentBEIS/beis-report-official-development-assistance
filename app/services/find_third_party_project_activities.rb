class FindThirdPartyProjectActivities
  include Pundit

  attr_accessor :organisation, :user, :fund_code

  def initialize(organisation:, user:, fund_code: nil)
    @organisation = organisation
    @user = user
    @fund_code = fund_code
  end

  def call
    third_party_projects = ThirdPartyProjectPolicy::Scope.new(user, projects_scope)
      .resolve
      .includes(
        :organisation,
        :extending_organisation,
        :implementing_organisations,
        :budgets,
        :parent,
        :commitment
      )
      .order("created_at ASC")

    if organisation.service_owner?
      third_party_projects.all
    else
      third_party_projects.where(organisation_id: organisation.id)
    end
  end

  private

  def projects_scope
    fund_code.nil? ? Activity.third_party_project : Activity.third_party_project.where(source_fund_code: fund_code)
  end
end
