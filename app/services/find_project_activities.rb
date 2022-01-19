class FindProjectActivities
  include Pundit

  attr_accessor :organisation, :user, :fund_code

  def initialize(organisation:, user:, fund_code: nil)
    @organisation = organisation
    @user = user
    @fund_code = fund_code
  end

  def call
    projects = ProjectPolicy::Scope.new(user, projects_scope)
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
      projects.all
    else
      projects.where(organisation_id: organisation.id)
    end
  end

  private

  def projects_scope
    fund_code.nil? ? Activity.project : Activity.project.where(source_fund_code: fund_code)
  end
end
