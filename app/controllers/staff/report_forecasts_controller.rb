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
      .includes([:parent_activity])
      .map { |forecast| ForecastPresenter.new(forecast) }
      .group_by { |forecast| ActivityPresenter.new(forecast.parent_activity) }

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
