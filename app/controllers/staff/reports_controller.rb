# frozen_string_literal: true

require "csv"

class Staff::ReportsController < Staff::BaseController
  include Secured
  include ActionController::Live

  def index
    if current_user.service_owner?
      reports_for_service_owner
    else
      reports_for_delivery_partner
    end
  end

  def show
    @report = Report.find(id)
    authorize @report
    @report_presenter = ReportPresenter.new(@report)

    respond_to do |format|
      format.html
      format.csv do
        fund = @report.fund
        @projects = Activity.project.where(organisation: @report.organisation).select { |activity| activity.associated_fund == fund }
        @third_party_projects = Activity.third_party_project.where(organisation: @report.organisation).select { |activity| activity.associated_fund == fund }
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
      flash[:notice] = t("action.report.update.success")
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

  def reports_for_service_owner
    inactive_reports
    active_reports_with_organisations
    submitted_reports_with_organisations
    in_review_reports_with_organisations
    awaiting_changes_reports_with_organisations
  end

  def reports_for_delivery_partner
    active_reports
    submitted_reports
    in_review_reports
    awaiting_changes_reports
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

  def submitted_reports_with_organisations
    submitted_reports = policy_scope(Report.where(state: :submitted)).includes([:fund, :organisation])
    authorize submitted_reports
    @submitted_report_presenters = submitted_reports.map { |report| ReportPresenter.new(report) }
  end

  def submitted_reports
    submitted_reports = policy_scope(Report.where(state: :submitted)).includes(:fund)
    authorize submitted_reports
    @submitted_report_presenters = submitted_reports.map { |report| ReportPresenter.new(report) }
  end

  def in_review_reports_with_organisations
    in_review_reports = policy_scope(Report.where(state: :in_review)).includes([:fund, :organisation])
    authorize in_review_reports
    @in_review_report_presenters = in_review_reports.map { |report| ReportPresenter.new(report) }
  end

  def in_review_reports
    in_review_reports = policy_scope(Report.where(state: :in_review)).includes(:fund)
    authorize in_review_reports
    @in_review_report_presenters = in_review_reports.map { |report| ReportPresenter.new(report) }
  end

  def awaiting_changes_reports_with_organisations
    awaiting_changes_reports = policy_scope(Report.where(state: :awaiting_changes)).includes([:fund, :organisation])
    authorize awaiting_changes_reports
    @awaiting_changes_report_presenters = awaiting_changes_reports.map { |report| ReportPresenter.new(report) }
  end

  def awaiting_changes_reports
    awaiting_changes_reports = policy_scope(Report.where(state: :awaiting_changes)).includes(:fund)
    authorize awaiting_changes_reports
    @awaiting_changes_report_presenters = awaiting_changes_reports.map { |report| ReportPresenter.new(report) }
  end

  def send_csv
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{ERB::Util.url_encode(@report.description)}.csv"
    response.stream.write ExportActivityToCsv.new(report: @report).headers
    @projects.each do |project|
      response.stream.write ExportActivityToCsv.new(activity: project, report: @report).call
    end
    @third_party_projects.each do |project|
      response.stream.write ExportActivityToCsv.new(activity: project, report: @report).call
    end
    response.stream.close
  end
end
