class Export::ActivityCommitmentColumn
  def initialize(activities:)
    @activities = activities
  end

  def headers
    ["Original Commitment"]
  end

  def rows
    return {} if @activities.empty?

    @activities.map { |activity|
      [activity.id, activity.commitment&.value]
    }.to_h
  end
end
