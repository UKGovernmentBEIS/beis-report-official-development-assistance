# frozen_string_literal: true

require "csv"

class Staff::ReportsController < Staff::BaseController
  include Secured
  include StreamCsvDownload
  include Reports::Breadcrumbed

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

  def send_csv
    export = Report::Export.new(reports: [@report])

    stream_csv_download(filename: export.filename, headers: export.headers) do |csv|
      export.rows.each do |row|
        csv << row
      end
    end
  end
end
