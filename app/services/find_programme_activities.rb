class FindProgrammeActivities
  include Pundit

  attr_accessor :organisation, :user

  def initialize(organisation:, user:)
    @organisation = organisation
    @user = user
  end

  def call
    programmes = ProgrammePolicy::Scope.new(user, Activity.programme)
      .resolve
      .includes(:organisation, :parent)
      .order("created_at ASC")
    programmes = if organisation.service_owner
      programmes.all
    else
      programmes.where(extending_organisation_id: organisation.id)
    end
    programmes
  end
end
