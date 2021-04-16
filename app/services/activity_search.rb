class ActivitySearch
  def initialize(user:, query:)
    @user = user
    @query = query.to_s.strip
  end

  def results
    activities.where(roda_identifier_compound: @query).or(
      activities.where(roda_identifier_fragment: @query)
    ).or(
      activities.where(delivery_partner_identifier: @query)
    ).or(
      activities.where(beis_identifier: @query)
    ).or(
      activities.where(previous_identifier: @query)
    )
  end

  private

  def activities
    @_activities ||= if @user.service_owner?
      Activity.all
    else
      Activity.where(organisation: @user.organisation)
    end
  end
end
