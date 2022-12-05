class FindThirdPartyProjectActivities
  include Pundit::Authorization

  attr_accessor :organisation, :user, :fund_code, :include_ispf_non_oda_activities

  def initialize(organisation:, user:, fund_code: nil, include_ispf_non_oda_activities: false)
    @organisation = organisation
    @user = user
    @fund_code = fund_code
    @include_ispf_non_oda_activities = include_ispf_non_oda_activities
  end

  def call
    ThirdPartyProjectPolicy::Scope.new(user, projects_scope)
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
    is_oda = [nil, true]
    is_oda << false if include_ispf_non_oda_activities

    query_conditions = {is_oda: is_oda}
    query_conditions[:source_fund_code] = fund_code if fund_code.present?
    query_conditions[:organisation_id] = organisation.id if !organisation.service_owner?

    Activity.third_party_project.where(query_conditions)
  end
end
