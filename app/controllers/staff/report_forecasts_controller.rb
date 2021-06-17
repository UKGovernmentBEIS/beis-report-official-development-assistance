# frozen_string_literal: true

class Staff::ReportForecastsController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = @report.reportable_activities

    render "staff/reports/forecasts"
  end
end
