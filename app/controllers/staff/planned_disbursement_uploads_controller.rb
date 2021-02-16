# frozen_string_literal: true

require "csv"

class Staff::PlannedDisbursementUploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  before_action :authorize_report

  def new
    @report_presenter = ReportPresenter.new(@report)
  end

  def show
    generator = ImportPlannedDisbursements::Generator.new

    stream_csv_download(filename: "forecasts.csv", headers: generator.column_headings) do |csv|
      @report.reportable_activities.each do |activity|
        csv << generator.csv_row(activity)
      end
    end
  end

  def update
    @report_presenter = ReportPresenter.new(@report)
    upload = CsvFileUpload.new(params[:report], :planned_disbursement_csv)
    @success = false

    if upload.valid?
      importer = ImportPlannedDisbursements.new(uploader: current_user)
      importer.import(upload.rows)
      @errors = importer.errors

      if @errors.empty?
        @success = true
        flash.now[:notice] = t("action.planned_disbursement.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.planned_disbursement.upload.file_missing_or_invalid")
    end
  end

  private def authorize_report
    @report = Report.find(params[:report_id])
    authorize @report, :show?
  end
end
