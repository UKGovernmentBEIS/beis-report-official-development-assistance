# frozen_string_literal: true

class Staff::ReportsStateController < Staff::BaseController
  include Secured

  def edit
    case report.state
    when "inactive"
      confirm_activation
    when "active"
      confirm_submission
    when "submitted"
      confirm_in_review
    when "in_review"
      params[:request_changes] ? confirm_request_changes : confirm_approve
    else
      authorize report
      redirect_to report_path(report)
    end
  end

  def update
    case report.state
    when "inactive"
      change_report_state_to_active
    when "active"
      change_report_state_to_submitted
    when "submitted"
      change_report_state_to_in_review
    when "in_review"
      params[:request_changes] ? change_report_state_to_awaiting_changes : change_report_state_to_approved
    else
      authorize report
      redirect_to report_path(report)
    end
  end

  private def confirm_activation
    authorize report, :activate?
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/activate/confirm"
  end

  private def change_report_state_to_active
    authorize report, :activate?
    report.update!(state: :active)
    report.create_activity key: "report.activated", owner: current_user
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/activate/complete"
  end

  private def confirm_submission
    authorize report, :submit?
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/submit/confirm"
  end

  private def change_report_state_to_submitted
    authorize report, :submit?
    report.update!(state: :submitted)
    report.create_activity key: "report.submitted", owner: current_user
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/submit/complete"
  end

  private def confirm_in_review
    authorize report, :review?
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/review/confirm"
  end

  private def change_report_state_to_in_review
    authorize report, :review?
    report.update!(state: :in_review)
    report.create_activity key: "report.in_review", owner: current_user
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/review/complete"
  end

  private def confirm_request_changes
    authorize report, :request_changes?
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/request_changes/confirm"
  end

  private def change_report_state_to_awaiting_changes
    authorize report, :request_changes?
    report.update!(state: :awaiting_changes)
    report.create_activity key: "report.awaiting_changes", owner: current_user
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/request_changes/complete"
  end

  private def confirm_approve
  end

  private def change_report_state_to_approved
  end

  private def report
    @report ||= Report.find(params[:report_id])
  end
end
