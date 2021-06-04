# frozen_string_literal: true

class Staff::ReportActivitiesController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)

    render "staff/reports/activities"
  end
end
