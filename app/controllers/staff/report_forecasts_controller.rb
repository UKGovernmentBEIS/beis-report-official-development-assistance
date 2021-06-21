# frozen_string_literal: true

class Staff::ReportForecastsController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = @report.reportable_activities
    @total_forecast = formatted(forecasts.sum(&:value))
    @grouped_forecasts = forecasts
      .map { |forecast| ForecastPresenter.new(forecast) }
      .group_by { |forecast| forecast.parent_activity_id }

    render "staff/reports/forecasts"
  end

  private

  def forecasts
    ForecastOverview
      .new(@report_activities.map(&:id))
      .latest_values
  end

  def formatted(bigdecimal)
    ActionController::Base.helpers.number_to_currency(bigdecimal, unit: "£")
  end
end
