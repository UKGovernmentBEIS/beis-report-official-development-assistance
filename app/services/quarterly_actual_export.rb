class QuarterlyActualExport
  HEADERS = [
    "Activity RODA Identifier",
    "Activity BEIS Identifier"
  ]

  def initialize(activities)
    @activities = activities.to_a
    load_actuals
  end

  def headers
    return HEADERS if @actuals.empty?

    HEADERS + financial_quarter_range.map(&:to_s)
  end

  def rows
    @activities.map do |activity|
      [activity.roda_identifier, activity.beis_identifier] + actual_row(activity)
    end
  end

  private

  def actual_row(activity)
    return [] if @actuals.empty?

    financial_quarter_range.map do |quarter|
      value = @actuals[[activity.id, quarter]]&.value || 0
      "%.2f" % value
    end
  end

  def load_actuals
    group_columns = "parent_activity_id, financial_year, financial_quarter"

    actual_relation = Actual
      .where(parent_activity: @activities)
      .group(group_columns)
      .select("#{group_columns}, SUM(value) AS value")

    @actuals = {}
    @financial_quarters = Set.new

    actual_relation.each do |actual|
      key = [actual.parent_activity_id, actual.own_financial_quarter]
      @actuals[key] = actual

      @financial_quarters.add(actual.own_financial_quarter)
    end
  end

  def financial_quarter_range
    @_financial_quarter_range ||= Range.new(*@financial_quarters.minmax)
  end
end
