# frozen_string_literal: true

class Staff::ReportVarianceController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)

    @activities = hierarchically_grouped_projects.map { |activity| ActivityPresenter.new(activity) }
    render "staff/reports/variance"
  end

  private

  def hierarchically_grouped_projects
    Activity.includes(:organisation).projects_and_third_party_projects_for_report(@report).hierarchically_grouped_projects
  end
end
