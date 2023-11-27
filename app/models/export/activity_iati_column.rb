class Export::ActivityIatiColumn
  def initialize(activities:)
    @activities = activities
  end

  def headers
    ["Published on IATI"]
  end

  def rows
    return {} if @activities.empty?

    @activities.map { |activity|
      [
        activity.id,
        I18n.t("summary.label.activity.publish_to_iati.#{activity.publish_to_iati}")
      ]
    }.to_h
  end
end
