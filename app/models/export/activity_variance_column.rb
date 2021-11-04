class Export::ActivityVarianceColumn
  def initialize(activities:, net_actual_spend_column_data:, forecast_column_data:, financial_quarter:)
    @activities = activities
    @net_actual_spend_column_data = net_actual_spend_column_data
    @forecast_column_data = forecast_column_data
    @financial_quarter = financial_quarter
  end

  def headers
    ["Variance #{@financial_quarter}"]
  end

  def rows
    return [] if @activities.empty?

    @activities.map { |activity|
      [activity.id, @forecast_column_data.fetch(activity.id, nil) - @net_actual_spend_column_data.fetch(activity.id, nil)]
    }.to_h
  end
end
