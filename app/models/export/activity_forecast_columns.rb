class Export::ActivityForecastColumns
  def initialize(activities:, report: nil)
    @activities = activities
    @report = report
  end

  def headers
    return [] if @activities.empty?

    forecast_financial_quarter_range.map do |financial_quarter|
      "Forecast #{financial_quarter}"
    end
  end

  def rows
    return [] if @activities.empty?

    @activities.map { |activity|
      [activity.id, forecast_data(activity)]
    }.to_h
  end

  private

  def forecast_data(activity)
    forecast_financial_quarter_range.map { |fq|
      forecasts_to_hash.fetch([activity.id, fq.quarter, fq.financial_year.start_year], 0)
    }
  end

  def activity_ids
    @activities.pluck(:id)
  end

  def forecasts
    @_forecasts ||= begin
      if @report.nil?
        ForecastOverview.new(activity_ids).latest_values
      else
        ForecastOverview.new(activity_ids).snapshot(@report).all_quarters.as_records
      end
    end
  end

  def forecasts_to_hash
    @_forecasts_to_hash ||= forecasts.each_with_object({}) { |forecast, hash|
      hash[[forecast.parent_activity_id, forecast.financial_quarter, forecast.financial_year]] = forecast.value
    }
  end

  def all_financial_quarters_with_forecasts
    return [] unless forecasts.present?
    forecasts.map(&:own_financial_quarter).uniq
  end

  def forecast_financial_quarter_range
    @_forecast_quarter_range ||= begin
      return [] if all_financial_quarters_with_forecasts.blank?

      if @report.nil?
        Range.new(all_financial_quarters_with_forecasts.min, all_financial_quarters_with_forecasts.max)
      else
        Range.new(report_financial_quarter(@report), all_financial_quarters_with_forecasts.max)
      end
    end
  end

  def report_financial_quarter(report)
    FinancialQuarter.new(report.financial_year, report.financial_quarter)
  end
end
