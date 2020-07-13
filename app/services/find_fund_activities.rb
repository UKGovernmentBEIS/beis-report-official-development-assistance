class FindFundActivities
  include Pundit

  attr_accessor :organisation, :user

  def initialize(organisation:, user:)
    @organisation = organisation
    @user = user
  end

  def call
    funds = FundPolicy::Scope.new(user, Activity.fund)
      .resolve
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
