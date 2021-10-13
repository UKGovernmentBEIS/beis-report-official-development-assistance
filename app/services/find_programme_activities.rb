class FindProgrammeActivities
  include Pundit

  attr_accessor :organisation, :user, :fund_code

  def initialize(organisation:, user:, fund_code: nil)
    @organisation = organisation
    @user = user
    @fund_code = fund_code
  end

  def call
    programmes = ProgrammePolicy::Scope.new(user, Activity.programme)
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
