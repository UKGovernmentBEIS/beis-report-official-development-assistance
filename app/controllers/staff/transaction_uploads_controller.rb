# frozen_string_literal: true

require "csv"

class Staff::TransactionUploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def new
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
  end

  def show
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
    filename = @report_presenter.filename_for_transactions_template

    stream_csv_download(filename: filename, headers: csv_headers) do |csv|
      reportable_activities.each do |activity|
        csv << csv_row(activity)
      end
    end
  end

  def update
    authorize report, :upload?

    @report_presenter = ReportPresenter.new(report)
    upload = CsvFileUpload.new(params[:report], :transaction_csv)
    @success = false

    if upload.valid?
      importer = ImportTransactions.new(report: report, uploader: current_user)
      importer.import(upload.rows)
      @errors = importer.errors

      if @errors.empty?
        imported_transactions = importer.imported_transactions.compact

        @total_transaction = TotalPresenter.new(imported_transactions.sum(&:value)).value
        @grouped_transactions = imported_transactions
          .map { |forecast| TransactionPresenter.new(forecast) }
          .group_by { |forecast| ActivityPresenter.new(forecast.parent_activity) }

        @success = true
        flash.now[:notice] = t("action.transaction.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.transaction.upload.file_missing_or_invalid")
    end
  end

  private def report
    @_report ||= Report.find(params[:report_id])
  end

  private def csv_headers
    ["Activity Name", "Activity Delivery Partner Identifier"] + ImportTransactions.column_headings
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
