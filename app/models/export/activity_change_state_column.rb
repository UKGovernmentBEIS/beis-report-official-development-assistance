class Export::ActivityChangeStateColumn
  def initialize(activities:, report:)
    @activities = activities
    @report = report
  end

  def headers
    ["Change state"]
  end

  def rows
    return [] if @activities.empty?

    @activities.map { |activity|
      [activity.id, state_of(activity: activity)]
    }.to_h
  end

  private

  def state_of(activity:)
    return nil unless all_activities_for_report.include?(activity.id)
    return "New" if all_new_activities.include?(activity.id)
    return "Changed" if all_changed_activities.include?(activity.id)
    "Unchanged"
  end

  def all_activities_for_report
    @_all_activities_for_report ||=
      Activity::ProjectsForReportFinder.new(report: @report).call.pluck(:id)
  end

  def all_new_activities
    @_all_new_activities ||= @report.new_activities.pluck(:id)
  end

  def all_changed_activities
    @_all_changed_activities ||= @report.activities_updated.pluck(:id)
  end
end
