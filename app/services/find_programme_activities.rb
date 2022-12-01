class FindProgrammeActivities
  include Pundit::Authorization

  attr_accessor :organisation, :user, :fund_code, :include_ispf_non_oda_activities

  def initialize(organisation:, user:, fund_code: nil, include_ispf_non_oda_activities: false)
    @organisation = organisation
    @user = user
    @fund_code = fund_code
    @include_ispf_non_oda_activities = include_ispf_non_oda_activities
  end

  def call
    is_oda = [nil, true]
    is_oda << false if include_ispf_non_oda_activities

    programmes = ProgrammePolicy::Scope.new(user, Activity.programme.where(is_oda: is_oda))
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

    return programmes if organisation.service_owner?

    query_conditions = {extending_organisation_id: organisation.id}
    query_conditions[:source_fund_code] = fund_code if fund_code.present?

    programmes.where(query_conditions)
  end
end
