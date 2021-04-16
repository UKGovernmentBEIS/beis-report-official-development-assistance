class ActivitySearch
  def initialize(user:, query:)
    @user = user
    @query = query.to_s.strip
  end

  def results
    search_fields = [
      :roda_identifier_compound,
      :roda_identifier_fragment,
      :delivery_partner_identifier,
      :beis_identifier,
      :previous_identifier,
    ]

    search_fields
      .map { |field| activities.where(field => @query) }
      .reduce { |a, b| a.or(b) }
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
