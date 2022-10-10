# frozen_string_literal: true

class ReportForecastsController < BaseController
  include Secured
  include Reports::Breadcrumbed

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    prepare_default_report_trail @report

    forecasts = @report.forecasts_for_reportable_activities

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = @report.reportable_activities
    @total_forecast = @report_presenter.summed_forecasts_for_reportable_activities
    @grouped_forecasts = forecasts
      .includes([:parent_activity])
      .map { |forecast| ForecastPresenter.new(forecast) }
      .group_by { |forecast| ActivityPresenter.new(forecast.parent_activity) }

    render "reports/forecasts"
  end
end
