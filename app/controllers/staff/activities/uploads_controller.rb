# frozen_string_literal: true

require "csv"

class Staff::Activities::UploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload
  include Reports::Breadcrumbed

  def new
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)

    prepare_default_report_trail(report)
    add_breadcrumb t("breadcrumb.report.upload_activities"), new_report_activities_upload_path(report)
  end

  def show
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
    filename = @report_presenter.filename_for_activities_template

    stream_csv_download(filename: filename, headers: csv_headers)
  end

  def update
    authorize report, :upload?

    @report_presenter = ReportPresenter.new(report)
    upload = CsvFileUpload.new(params[:report], :activity_csv)
    @success = false

    prepare_default_report_trail(report)
    add_breadcrumb t("breadcrumb.report.upload_activities"), new_report_activities_upload_path(report)

    if upload.valid?
      importer = Activity::Import.new(
        uploader: current_user,
        partner_organisation: current_user.organisation,
        report: report
      )
      importer.import(upload.rows)
      @errors = importer.errors
      @activities = {created: importer.created, updated: importer.updated}

      if @errors.empty?
        @success = true
        flash.now[:notice] = t("action.activity.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.activity.upload.file_missing_or_invalid")
    end
  end

  private def report
    @_report ||= Report.find(params[:report_id])
  end

  private def csv_headers
    ["RODA ID"] + Activity::Import.column_headings
  end
end
