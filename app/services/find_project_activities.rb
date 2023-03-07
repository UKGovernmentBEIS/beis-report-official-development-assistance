class FindProjectActivities
  include Pundit::Authorization

  attr_accessor :organisation, :user, :fund_code

  def initialize(organisation:, user:, fund_code: nil)
    @organisation = organisation
    @user = user
    @fund_code = fund_code
  end

  def call
    ProjectPolicy::Scope.new(user, projects_scope)
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
  end

  private

  def projects_scope
    query_conditions = {}
    query_conditions[:source_fund_code] = fund_code if fund_code.present?
    query_conditions[:organisation_id] = organisation.id if !organisation.service_owner?

    Activity.project.where(query_conditions)
  end
end
