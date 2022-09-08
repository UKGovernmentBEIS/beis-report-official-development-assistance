class ActivitySearch
  include ActiveModel::Model

  attr_reader :query

  def initialize(user: nil, query: nil)
    @user = user
    @query = query.to_s.strip
  end

  def results
    search_fields = [
      :roda_identifier,
      :partner_organisation_identifier,
      :beis_identifier,
      :previous_identifier,
      :transparency_identifier
    ]

    result = search_fields
      .map { |field| activities.where("LOWER(#{field}) = ?", @query.downcase) }
      .reduce { |a, b| a.or(b) }
      .or(activities.where("LOWER(title) LIKE ?", "%#{@query.downcase}%"))

    if result.blank?
      result = activities.where("LOWER(roda_identifier) LIKE ?", "%#{@query.downcase}%")
    end

    result
  end

  private

  def activities
    @_activities ||= if @user.service_owner?
      Activity.all
    else
      Activity.where(extending_organisation: @user.organisation)
    end
  end
end
