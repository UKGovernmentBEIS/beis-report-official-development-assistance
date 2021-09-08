# frozen_string_literal: true

require "csv"

class Staff::ActualUploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload
  include Reports::Breadcrumbed

  def new
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)

    prepare_default_report_trail(report)
    add_breadcrumb t("breadcrumb.report.upload_actuals"), new_report_actual_upload_path(report)
  end

  def show
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
    filename = @report_presenter.filename_for_actuals_template

    stream_csv_download(filename: filename, headers: csv_headers) do |csv|
      reportable_activities.each do |activity|
        csv << csv_row(activity)
      end
    end
  end

  def update
    authorize report, :upload?

    @report_presenter = ReportPresenter.new(report)
    upload = CsvFileUpload.new(params[:report], :actual_csv)
    @success = false

    prepare_default_report_trail(report)
    add_breadcrumb t("breadcrumb.report.upload_actuals"), new_report_actual_upload_path(report)

    if upload.valid?
      importer = ImportActuals.new(report: report, uploader: current_user)
      importer.import(upload.rows)
      @errors = importer.errors

      if @errors.empty?
        imported_actuals = importer.imported_actuals.compact

        @total_actuals = TotalPresenter.new(imported_actuals.sum(&:value)).value
        @grouped_actuals = imported_actuals
          .map { |actual| TransactionPresenter.new(actual) }
          .group_by { |actual| ActivityPresenter.new(actual.parent_activity) }

        @success = true
        flash.now[:notice] = t("action.actual.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.actual.upload.file_missing_or_invalid")
    end
  end

  private def report
    @_report ||= Report.find(params[:report_id])
  end

  private def csv_headers
    ["Activity Name", "Activity Delivery Partner Identifier"] + ImportActuals.column_headings
  end

  private def csv_row(activity)
    [
      activity.title,
      activity.delivery_partner_identifier,
      activity.roda_identifier,
      report.financial_quarter.to_s,
      report.financial_year.to_s,
      "%.2f" % 0,
    ]
  end

  def reportable_activities
    report.reportable_activities.hierarchically_grouped_projects
  end
end
