# frozen_string_literal: true

require "csv"

class Staff::ActivityUploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  before_action :authorize_report

  def new
    @report_presenter = ReportPresenter.new(@report)
  end

  def show
    @report_presenter = ReportPresenter.new(@report)
    filename = @report_presenter.filename_for_activities_template

    stream_csv_download(filename: filename, headers: csv_headers)
  end

  def update
    @report_presenter = ReportPresenter.new(@report)
    upload = CsvFileUpload.new(params[:report], :activity_csv)
    @success = false

    if upload.valid?
      importer = Activities::ImportFromCsv.new(uploader: current_user, delivery_partner_organisation: current_user.organisation)
      importer.import(upload.rows)
      @errors = importer.errors

      if @errors.empty?
        @success = true
        flash.now[:notice] = t("action.activity.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.activity.upload.file_missing_or_invalid")
    end
  end

  private def authorize_report
    @report = Report.find(params[:report_id])
    authorize @report, :show?
  end

  private def csv_headers
    ["RODA ID"] + Activities::ImportFromCsv.column_headings
  end
end
