# frozen_string_literal: true

require "csv"

class Actuals::UploadsController < BaseController
  include Secured
  include StreamCsvDownload
  include Reports::Breadcrumbed

  def new
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)

    prepare_default_report_trail(report)
    add_breadcrumb t("breadcrumb.report.upload_actuals"), new_report_actuals_upload_path(report)
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
    add_breadcrumb t("breadcrumb.report.upload_actuals"), new_report_actuals_upload_path(report)

    if upload.valid?
      if ROLLOUT.active?(:use_new_activity_actual_refund_comment_importer)
        importer = Import::Csv::ActivityActualRefundComment::FileService.new(report: report, user: current_user, csv_rows: upload.rows)
        import_result = importer.import!

        @errors = importer.errors

        if import_result
          # the old import and the UI combine Actuals and Refunds, so we have to do the same
          # once we have tested the import, we will come back and make the UI improvements
          # to make the most of the new importer
          imported_actuals_and_refunds = importer.imported_actuals + importer.imported_refunds

          @total_actuals = total_transactions(imported_actuals_and_refunds)
          @grouped_actuals = grouped_transactions(imported_actuals_and_refunds)
          @success = true

          flash.now[:notice] = t("action.actual.upload.success")
        elsif @errors.empty?
          flash.now[:error] = t("import.csv.activity_actual_refund_comment.errors.headers")
        end
      else
        importer = Actual::Import.new(report: report, uploader: current_user)
        importer.import(upload.rows)
        @errors = importer.errors

        if @errors.empty?
          imported_actuals_and_refunds = importer.imported_actuals

          @total_actuals = total_transactions(imported_actuals_and_refunds)
          @grouped_actuals = grouped_transactions(imported_actuals_and_refunds)
          @success = true

          flash.now[:notice] = t("action.actual.upload.success")
        else
          @invalid_with_comment = importer.invalid_with_comment
        end
      end

    else
      @errors = []
      flash.now[:error] = t("action.actual.upload.file_missing_or_invalid")
    end
  end

  private def total_transactions(transactions)
    TotalPresenter.new(transactions.sum(&:value)).value
  end

  private def grouped_transactions(transactions)
    transactions
      .map { |transaction| TransactionPresenter.new(transaction) }
      .group_by { |transaction| ActivityPresenter.new(transaction.parent_activity) }
  end

  private def report
    @_report ||= Report.find(params[:report_id])
  end

  private def csv_headers
    ["Activity Name", "Activity Partner Organisation Identifier"] + Actual::Import.column_headings
  end

  private def csv_row(activity)
    [
      activity.title,
      activity.partner_organisation_identifier,
      activity.roda_identifier,
      report.financial_quarter.to_s,
      report.financial_year.to_s,
      "%.2f" % 0
    ]
  end

  def reportable_activities
    report.reportable_activities.hierarchically_grouped_projects
  end
end
