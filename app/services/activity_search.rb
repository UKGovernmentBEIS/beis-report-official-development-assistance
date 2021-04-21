class ActivitySearch
  include ActiveModel::Model

  attr_reader :query

  def initialize(user: nil, query: nil)
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
      .map { |field| activities.where("LOWER(#{field}) = ?", @query.downcase) }
      .reduce { |a, b| a.or(b) }
      .or(activities.where("LOWER(title) LIKE ?", "%#{@query.downcase}%"))
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
