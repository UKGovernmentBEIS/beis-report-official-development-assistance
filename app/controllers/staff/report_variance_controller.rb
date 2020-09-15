# frozen_string_literal: true

class Staff::ReportVarianceController < Staff::BaseController
  include Secured

  def show
    @report = Report.find(params["report_id"])
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = level_c_and_d_activities_for_report(report: @report)

    @activities = @report_activities.map { |activity| ActivityPresenter.new(activity) }
    render "staff/reports/variance"
  end

  private def level_c_and_d_activities_for_report(report:)
    return Activity.none if report.nil?
    Activity.where(level: [:project, :third_party_project], organisation: report.organisation).select { |activity| activity.associated_fund == report.fund }
  end
end
