# frozen_string_literal: true

require "csv"

class Staff::PlannedDisbursementUploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def new
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
  end

  def show
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
    generator = ImportPlannedDisbursements::Generator.new(report)
    filename = @report_presenter.filename_for_forecasts_template

    stream_csv_download(filename: filename, headers: generator.column_headings) do |csv|
      report.reportable_activities.each do |activity|
        csv << generator.csv_row(activity)
      end
    end
  end

  def update
    authorize report, :upload?

    @report_presenter = ReportPresenter.new(report)
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

  private def report
    @_report ||= Report.find(params[:report_id])
  end
end
