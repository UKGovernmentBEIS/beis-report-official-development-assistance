class FindProgrammeActivities
  include Pundit

  attr_accessor :organisation, :current_user

  def initialize(organisation:, current_user:)
    @organisation = organisation
    @current_user = current_user
  end

  def call
    programmes = policy_scope(Activity.programme, policy_scope_class: ProgrammePolicy::Scope)
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
