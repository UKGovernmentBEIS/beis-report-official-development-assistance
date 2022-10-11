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
      [activity.id, comments_formatted_for_csv(activity.comments_for_report(report_id: @report.id))]
    }.to_h
  end

  private

  def comments_formatted_for_csv(comments)
    comments.pluck(:body).join("|")
  end
end
