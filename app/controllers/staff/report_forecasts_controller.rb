# frozen_string_literal: true

class Staff::ReportForecastsController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    forecasts = @report.forecasts_for_reportable_activities

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = @report.reportable_activities
    @total_forecast = TotalPresenter.new(forecasts.sum(&:value)).value
    @grouped_forecasts = forecasts
      .includes([:parent_activity])
      .map { |forecast| ForecastPresenter.new(forecast) }
      .group_by { |forecast| ActivityPresenter.new(forecast.parent_activity) }

    render "staff/reports/forecasts"
  end
end
