# frozen_string_literal: true

require "csv"

class Staff::ReportsController < Staff::BaseController
  include Secured
  include ActionController::Live

  def index
    inactive_reports if current_user.service_owner?
    current_user.service_owner? ? active_reports_with_organisations : active_reports
  end

  def show
    report = Report.find(id)
    authorize report

    @report_presenter = ReportPresenter.new(report)

    respond_to do |format|
      format.html
      format.csv do
        fund = @report_presenter.fund
        @projects = Activity.project.where(organisation: @report_presenter.organisation).select { |activity| activity.associated_fund == fund }
        @third_party_projects = Activity.third_party_project.where(organisation: @report_presenter.organisation).select { |activity| activity.associated_fund == fund }
        send_csv
      end
    end
  end

  def edit
    @report = Report.find(id)
    authorize @report
  end

  def update
    @report = Report.find(id)
    authorize @report

    @report.assign_attributes(report_params)
    if @report.valid?
      @report.save!
      @report.create_activity key: "report.update", owner: current_user
      activate!
      flash[:notice] = I18n.t("action.report.update.success")
      redirect_to reports_path
    else
      render :edit
    end
  end

  private

  def id
    params[:id]
  end

  def report_params
    params.require(:report).permit(:deadline, :description)
  end

  def activate!
    if @report.deadline.present? && @report.deadline > Date.today
      @report.state = :active
      @report.save!
      @report.create_activity key: "report.activate", owner: current_user
    end
  end

  def inactive_reports
    inactive_reports = policy_scope(Report.where(state: :inactive)).includes([:fund, :organisation])
    authorize inactive_reports
    @inactive_report_presenters = inactive_reports.map { |report| ReportPresenter.new(report) }
  end

  def active_reports_with_organisations
    active_reports = policy_scope(Report.where(state: :active)).includes([:fund, :organisation])
    authorize active_reports
    @active_report_presenters = active_reports.map { |report| ReportPresenter.new(report) }
  end

  def active_reports
    active_reports = policy_scope(Report.where(state: :active)).includes(:fund)
    authorize active_reports
    @active_report_presenters = active_reports.map { |report| ReportPresenter.new(report) }
  end

  def send_csv
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{ERB::Util.url_encode(@report_presenter.description)}.csv"
    response.stream.write ExportActivityToCsv.new.headers(report: @report_presenter)
    @projects.each do |project|
      response.stream.write ExportActivityToCsv.new(activity: project).call
    end
    @third_party_projects.each do |project|
      response.stream.write ExportActivityToCsv.new(activity: project).call
    end
    response.stream.close
  end
end
