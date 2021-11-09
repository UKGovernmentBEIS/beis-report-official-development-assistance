class Export::ActivityCommentsColumn
  def initialize(activities:, report:)
    @activities = activities
    @report = report
  end

  def headers
    ["Comments in report"]
  end

  def rows
    return [] if @activities.empty?

    @activities.map { |activity|
      [activity.id, comments_for_activity(activity).join("\n----\n")]
    }.to_h
  end

  private

  def all_comments_for_report
    @_comments ||= @report.comments.includes(:commentable)
  end

  def comments_for_activity(activity)
    all_comments_for_report.select { |comment|
      comment.associated_activity.id == activity.id
    }.pluck :body
  end
end
