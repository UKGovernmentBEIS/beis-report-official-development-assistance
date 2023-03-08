# frozen_string_literal: true

require "csv"

class Activities::UploadsController < BaseController
  include Secured
  include StreamCsvDownload
  include Reports::Breadcrumbed

  def new
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
    @is_ispf = report.for_ispf?

    prepare_default_report_trail(report)
    add_breadcrumb t("breadcrumb.report.upload_activities"), new_report_activities_upload_path(report)
  end

  def show
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
    type = params[:type].to_sym
    is_oda = Activity::Import.is_oda_by_type(type: type)
    filename = @report_presenter.filename_for_activities_template(is_oda: is_oda)
    headers = Activity::Import::Field.where_level_and_type(level: :level_c_d, type: type).map(&:heading)

    stream_csv_download(filename: filename, headers: headers)
  end

  def update
    authorize report, :upload?

    @report_presenter = ReportPresenter.new(report)
    upload = CsvFileUpload.new(params[:report], :activity_csv)
    @success = false
    @type = CGI.escapeHTML(params[:type]).to_sym
    is_oda = Activity::Import.is_oda_by_type(type: @type)

    prepare_default_report_trail(report)
    add_breadcrumb t("breadcrumb.report.upload_activities"), new_report_activities_upload_path(report)

    if upload.valid?
      importer = Activity::Import.new(
        uploader: current_user,
        partner_organisation: current_user.organisation,
        report: report,
        is_oda: is_oda
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
end
