class ActivitySearch
  def initialize(user:, query:)
    @user = user
    @query = query.to_s.strip
  end

  def results
    activities.where(roda_identifier_compound: @query).or(
      activities.where(roda_identifier_fragment: @query)
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
