# frozen_string_literal: true

require "csv"

class ReportsController < BaseController
  include Secured
  include StreamCsvDownload
  include Reports::Breadcrumbed

  after_action :skip_policy_scope, only: [:index]

  def index
    add_breadcrumb "Reports", :reports_path

    if current_user.service_owner?
      @grouped_reports = Report::GroupedReportsFetcher.new
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

  def download
    @report = Report.find(id)
    authorize @report

    report_csv = Export::S3Downloader.new(filename: @report.export_filename).download

    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=#{ERB::Util.url_encode(@report.export_filename)}"
    response.stream.write(report_csv)
    response.stream.close
  end

  def new
    add_breadcrumb "Reports", :reports_path

    @report = Report.new
    @funds = Activity.fund

    authorize @report
  end

  def create
    add_breadcrumb "Reports", :reports_path

    @report = Report.new
    authorize @report

    @funds = Activity.fund

    @report.assign_attributes(report_creatable_params.merge(state: "active"))
    if @report.valid?(:new)
      @report.save
      flash[:notice] = t("action.report.create.success")
      redirect_to reports_path
    else
      render :new
    end
  end

  def edit
    add_breadcrumb "Reports", :reports_path

    @report = Report.find(id)
    authorize @report

    @report_presenter = ReportPresenter.new(@report)
  end

  def update
    add_breadcrumb "Reports", :reports_path

    @report = Report.find(id)
    authorize @report

    @report_presenter = ReportPresenter.new(@report)

    @report.assign_attributes(report_updateable_params)
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

  def report_creatable_params
    params.require(:report).permit(
      :financial_quarter,
      :financial_year,
      :fund_id,
      :is_oda,
      :organisation_id,
      :deadline,
      :description
    )
  end

  def report_updateable_params
    params.require(:report).permit(:deadline, :description)
  end

  def send_csv
    export = Export::Report.new(report: @report)

    stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
      export.rows.each do |row|
        csv << row
      end
    end
  end
end
