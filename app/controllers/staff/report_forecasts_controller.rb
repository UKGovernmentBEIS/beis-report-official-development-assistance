# frozen_string_literal: true

class Staff::ReportForecastsController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = @report.reportable_activities
    @grouped_forecasts = ForecastOverview
      .new(@report_activities.map(&:id))
      .latest_values
      .group_by { |forecast| forecast.parent_activity_id }

    render "staff/reports/forecasts"
  end
end
