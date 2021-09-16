# frozen_string_literal: true

require "csv"

class Staff::ReportsController < Staff::BaseController
  include Secured
  include StreamCsvDownload
  include Reports::Breadcrumbed

  def index
    add_breadcrumb "Reports", :reports_path

    if current_user.service_owner?
      respond_to do |format|
        format.html do
          @grouped_reports = Report::GroupedReportsFetcher.new
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
      redirect_to organisation_reports_path(organisation_id: current_user.organisation.id)
    end
  end

  def show
    @report = Report.find(id)
    authorize @report

    @report_presenter = ReportPresenter.new(@report)

    prepare_default_report_trail @report

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
    export = Report::Export.new(reports: [@report])

    stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
      export.rows.each do |row|
        csv << row
      end
    end
  end

  def downloadable_reports_for_beis_users
    @downloadable_reports_for_beis_users ||= begin
      report_sets = [
        active_reports(including: [:organisation]),
        submitted_reports(including: [:organisation]),
        in_review_reports(including: [:organisation]),
        awaiting_changes_reports(including: [:organisation]),
      ]
      report_sets.sum.sort_by { |report| report.organisation.name }
    end
  end

  def reports_have_same_quarter?
    downloadable_reports_for_beis_users.map(&:financial_quarter).uniq.length == 1
  end

  def send_all_reports_csv
    export = Report::Export.new(reports: downloadable_reports_for_beis_users, export_type: :all)

    stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
      export.rows.each do |row|
        csv << row
      end
    end
  end
end
