# frozen_string_literal: true

class Staff::ReportVarianceController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = Activity.projects_and_third_party_projects_for_report(@report)

    @activities = @report_activities.map { |activity| ActivityPresenter.new(activity) }
    render "staff/reports/variance"
  end
end
