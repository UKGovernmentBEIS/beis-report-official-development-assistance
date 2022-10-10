# frozen_string_literal: true

class Staff::ReportActivitiesController < Staff::BaseController
  include Secured
  include Reports::Breadcrumbed

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    prepare_default_report_trail @report

    @report_presenter = ReportPresenter.new(@report)
    @updated_activities = @report.activities_updated
    @new_activities = @report.new_activities

    render "staff/reports/activities"
  end
end
