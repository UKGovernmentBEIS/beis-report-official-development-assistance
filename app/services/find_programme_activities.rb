class FindProgrammeActivities
  include Pundit

  attr_accessor :organisation, :user

  def initialize(organisation:, user:)
    @organisation = organisation
    @user = user
  end

  def call(eager_load_parent: true)
    eager_load_associations = [:organisation]
    eager_load_associations << :parent if eager_load_parent

    programmes = ProgrammePolicy::Scope.new(user, Activity.programme)
      .resolve
      .includes(eager_load_associations)
      .order("created_at ASC")

    programmes = if organisation.service_owner
      programmes.all
    else
      programmes.where(extending_organisation_id: organisation.id)
    end
    programmes
  end
end
