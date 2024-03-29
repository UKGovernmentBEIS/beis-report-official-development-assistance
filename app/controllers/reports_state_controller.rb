# frozen_string_literal: true

class ReportsStateController < BaseController
  include Secured

  STATE_TO_POLICY_ACTION = {
    "active" => "activate",
    "submitted" => "submit",
    "in_review" => "review",
    "awaiting_changes" => "request_changes",
    "qa_completed" => "mark_qa_completed",
    "approved" => "approve"
  }

  def edit
    case report.state
    when "active"
      show_state_change_confirmation(:submit)
    when "submitted"
      show_state_change_confirmation(:review)
    when "in_review"
      params[:request_changes] ? show_state_change_confirmation(:request_changes) : show_state_change_confirmation(:mark_qa_completed)
    when "qa_completed"
      params[:request_changes] ? show_state_change_confirmation(:request_changes) : show_state_change_confirmation(:approve)
    when "awaiting_changes"
      show_state_change_confirmation(:submit)
    else
      authorize report
      redirect_to report_path(report)
    end
  end

  def update
    state = params[:state]

    Report.transaction do
      if STATE_TO_POLICY_ACTION.key?(state)
        change_report_state_to(state)
      else
        authorize report
        redirect_to report_path(report)
      end
    end
  end

  private def show_state_change_confirmation(policy_action)
    authorize report, policy_action.to_s + "?"
    @report_presenter = ReportPresenter.new(report)
    render "reports_state/#{policy_action}/confirm"
  end

  private def change_report_state_to(state)
    policy_action = STATE_TO_POLICY_ACTION.fetch(state)

    unless report.valid?(policy_action.to_sym)
      authorize report
      flash[:error] = {title: t("action.report.#{policy_action}.failure"), errors: report.errors}
      return redirect_to report_path(report)
    end

    unless report.state == state
      authorize report, policy_action + "?"
      report.update!(state: state)

      Report::SendStateChangeEmails.new(report).send!

      if report.state == "approved"
        report.update!(approved_at: Time.current)
        ReportExportUploaderJob.perform_later(requester_id: current_user.id, report_id: report.id)
      end
    end

    @report_presenter = ReportPresenter.new(report)
    render "reports_state/#{policy_action}/complete"
  end

  private def report
    @report ||= Report.lock.find(params[:report_id])
  end
end
