# frozen_string_literal: true

class Staff::ReportsStateController < Staff::BaseController
  include Secured

  STATE_TO_POLICY_ACTION = {
    active: :activate,
    submitted: :submit,
    in_review: :review,
    awaiting_changes: :request_changes,
    approved: :approve,
  }

  def edit
    case report.state
    when "inactive"
      show_state_change_confirmation(:activate)
    when "active"
      show_state_change_confirmation(:submit)
    when "submitted"
      show_state_change_confirmation(:review)
    when "in_review"
      params[:request_changes] ? show_state_change_confirmation(:request_changes) : show_state_change_confirmation(:approve)
    when "awaiting_changes"
      show_state_change_confirmation(:submit)
    else
      authorize report
      redirect_to report_path(report)
    end
  end

  def update
    case report.state
    when "inactive"
      change_report_state_to(:active)
    when "active"
      change_report_state_to(:submitted)
    when "submitted"
      change_report_state_to(:in_review)
    when "in_review"
      params[:request_changes] ? change_report_state_to(:awaiting_changes) : change_report_state_to(:approved)
    when "awaiting_changes"
      change_report_state_to(:submitted)
    else
      authorize report
      redirect_to report_path(report)
    end
  end

  private def show_state_change_confirmation(policy_action)
    authorize report, policy_action.to_s + "?"
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports_state/#{policy_action}/confirm"
  end

  private def change_report_state_to(state)
    policy_action = STATE_TO_POLICY_ACTION.fetch(state).to_s

    authorize report, policy_action + "?"

    if report.valid?
      report.update!(state: state)
      report.create_activity key: "report.state.changed_to.#{state}", owner: current_user
      @report_presenter = ReportPresenter.new(report)
      render "staff/reports_state/#{policy_action}/complete"
    else
      flash[:error] = t("action.report.#{policy_action}.failure")
      redirect_to report_path(report)
    end
  end

  private def report
    @report ||= Report.find(params[:report_id])
  end
end
