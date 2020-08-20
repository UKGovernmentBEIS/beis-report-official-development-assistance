# frozen_string_literal: true

class Staff::ReportsStateController < Staff::BaseController
  include Secured

  def edit
    report = Report.find(params[:report_id])
    case report.state
    when "inactive"
      confirm_activation
    when "active"
      confirm_submission
    else
      authorize report
      redirect_to report_path(report)
    end
  end

  def update
    report = Report.find(params[:report_id])
    case report.state
    when "inactive"
      change_report_state_to_active
    when "active"
      change_report_state_to_submitted
    else
      authorize report
      redirect_to report_path(report)
    end
  end

  private def confirm_activation
    report = Report.find(params[:report_id])
    authorize report, :activate?
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/activate/confirm"
  end

  private def change_report_state_to_active
    report = Report.find(params[:report_id])
    authorize report, :activate?
    report.update!(state: :active)
    report.create_activity key: "report.activated", owner: current_user
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/activate/complete"
  end

  private def confirm_submission
    report = Report.find(params[:report_id])
    authorize report, :submit?
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/submit/confirm"
  end

  private def change_report_state_to_submitted
    report = Report.find(params[:report_id])
    authorize report, :submit?
    report.update!(state: :submitted)
    report.create_activity key: "report.submitted", owner: current_user
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/submit/complete"
  end
end
