class FindFundActivities
  include Pundit

  attr_accessor :organisation, :current_user

  def initialize(organisation:, current_user:)
    @organisation = organisation
    @current_user = current_user
  end

  def call
    funds = policy_scope(Activity.funds, policy_scope_class: FundPolicy::Scope)
      .includes(:organisation)
      .order("created_at ASC")
    funds = if organisation.service_owner
      funds.all
    else
      funds.where(organisation_id: organisation.id)
    end
    funds
  end
end
