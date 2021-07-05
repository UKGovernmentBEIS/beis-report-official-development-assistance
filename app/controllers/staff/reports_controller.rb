# frozen_string_literal: true

require "csv"

class Staff::ReportsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def index
    if current_user.service_owner?

      respond_to do |format|
        format.html do
          reports_for_service_owner
        end
        format.csv do
          if reports_have_same_quarter?
            send_all_reports_csv
          else
            flash[:error] = t("action.report.download.failure")
            redirect_to action: "index"
          end
        end
      end
    else
      reports_for_delivery_partner
    end
  end

  def show
    @report = Report.find(id)
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
    @report_activities = Activity.projects_and_third_party_projects_for_report(@report)

    respond_to do |format|
      format.html do
        render :show
      end
      format.csv do
        send_csv
      end
    end
  end

  def edit
    @report = Report.find(id)
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
  end

  def update
    @report = Report.find(id)
    authorize @report

    @report_presenter = ReportPresenter.new(@report)

    @report.assign_attributes(report_params)
    if @report.valid?(:edit)
      @report.save
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
    active_reports(including: [:organisation])
    submitted_reports(including: [:organisation])
    in_review_reports(including: [:organisation])
    awaiting_changes_reports(including: [:organisation])
    approved_reports(including: [:organisation])
  end

  def reports_for_delivery_partner
    active_reports
    submitted_reports
    in_review_reports
    awaiting_changes_reports
    approved_reports
  end

  def inactive_reports(including: [:organisation])
    inactive_reports = policy_scope(Report.inactive).includes([:fund] + including)
    authorize inactive_reports
    @inactive_report_presenters = inactive_reports.map { |report| ReportPresenter.new(report) }
  end

  def active_reports(including: [])
    active_reports = policy_scope(Report.active).includes([:fund] + including)
    authorize active_reports
    @active_report_presenters = active_reports.map { |report| ReportPresenter.new(report) }
  end

  def submitted_reports(including: [])
    submitted_reports = policy_scope(Report.submitted).includes([:fund] + including)
    authorize submitted_reports
    @submitted_report_presenters = submitted_reports.map { |report| ReportPresenter.new(report) }
  end

  def in_review_reports(including: [])
    in_review_reports = policy_scope(Report.in_review).includes([:fund] + including)
    authorize in_review_reports
    @in_review_report_presenters = in_review_reports.map { |report| ReportPresenter.new(report) }
  end

  def awaiting_changes_reports(including: [])
    awaiting_changes_reports = policy_scope(Report.awaiting_changes).includes([:fund] + including)
    authorize awaiting_changes_reports
    @awaiting_changes_report_presenters = awaiting_changes_reports.map { |report| ReportPresenter.new(report) }
  end

  def approved_reports(including: [])
    approved_reports = policy_scope(Report.approved.in_historical_order).includes([:fund] + including)
    authorize approved_reports
    @approved_report_presenters = approved_reports.map { |report| ReportPresenter.new(report) }
  end

  def send_csv
    filename = @report_presenter.filename_for_report_download
    headers = ExportActivityToCsv.new(report: @report).headers

    stream_csv_download(filename: filename, headers: headers) do |csv|
      @report_activities.each do |activity|
        csv << ExportActivityToCsv.new(activity: activity, report: @report).call
      end
    end
  end

  def downloadable_reports_for_beis_users
    report_sets = [
      active_reports(including: [:organisation]),
      submitted_reports(including: [:organisation]),
      in_review_reports(including: [:organisation]),
      awaiting_changes_reports(including: [:organisation]),
    ]
    report_sets.sum.sort_by { |report| report.organisation.name }
  end

  def report_activities_sorted_by_level(report)
    Activity
      .includes(:organisation, :extending_organisation, :implementing_organisations)
      .projects_and_third_party_projects_for_report(report)
      .sort_by { |a| a.level }
  end

  def reports_have_same_quarter?
    downloadable_reports_for_beis_users.map(&:financial_quarter).uniq.length == 1
  end

  def send_all_reports_csv
    report_sample = downloadable_reports_for_beis_users.first
    headers = ExportActivityToCsv.new(report: report_sample).headers
    filename = ReportPresenter.new(report_sample).filename_for_all_reports_download

    stream_csv_download(filename: filename, headers: headers) do |csv|
      downloadable_reports_for_beis_users.each do |report|
        report_activities_sorted_by_level(report).each do |activity|
          csv << ExportActivityToCsv.new(activity: activity, report: report).call
        end
      end
    end
  end
end
