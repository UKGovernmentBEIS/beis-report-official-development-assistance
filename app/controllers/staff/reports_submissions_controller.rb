# frozen_string_literal: true

class Staff::ReportsSubmissionsController < Staff::BaseController
  include Secured

  def show
    report = Report.find(params[:report_id])
    authorize report
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports/submit"
  end

  def update
    @report = Report.find(params[:report_id])
    authorize @report

    @report.state = :submitted
    if @report.valid?
      @report.save!
      @report.create_activity key: "report.submitted", owner: current_user
      redirect_to complete_report_submit_path(@report)
    else
      flash[:notice] = I18n.t("action.report.submit.failure")
      redirect_to reports_path
    end
  end

  def complete
    report = Report.find(params[:report_id])
    authorize report
    @report_presenter = ReportPresenter.new(report)
    render "staff/reports/complete"
  end
end
