class FindProgrammeActivities
  include Pundit

  attr_accessor :organisation, :user, :fund_id

  def initialize(organisation:, user:, fund_id: nil)
    @organisation = organisation
    @user = user
    @fund_id = fund_id
  end

  def call(eager_load_parent: true)
    eager_load_associations = [:organisation]
    eager_load_associations << :parent if eager_load_parent

    programmes = ProgrammePolicy::Scope.new(user, Activity.programme)
      .resolve
      .includes(eager_load_associations)
      .order("created_at ASC")

    return programmes if organisation.service_owner

    query_conditions = {extending_organisation_id: organisation.id}
    query_conditions[:parent_id] = fund_id if fund_id.present?

    programmes.where(query_conditions)
  end
end
