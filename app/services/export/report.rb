class Export::Report
  def initialize(report:)
    @report = report
    attributes_in_order = Export::ActivityAttributesOrder.attributes_in_order

    @activity_attributes =
      Export::ActivityAttributesColumns
        .new(activities: activities, attributes: attributes_in_order)
  end

  def headers
    @activity_attributes.headers
  end

  def rows
    @activity_attributes.rows
  end

  private

  def activities
    @activities ||= begin
      Activity::ProjectsForReportFinder.new(
        report: @report,
        scope: Activity.all
      ).call.sort_by { |a| a.level }
    end
  end
end
