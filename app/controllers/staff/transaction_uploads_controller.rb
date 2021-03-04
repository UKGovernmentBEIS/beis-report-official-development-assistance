# frozen_string_literal: true

require "csv"

class Staff::TransactionUploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  before_action :authorize_report

  def new
    @report_presenter = ReportPresenter.new(@report)
  end

  def show
    @report_presenter = ReportPresenter.new(@report)
    filename = "#{@report_presenter.financial_quarter_and_year}-#{@report_presenter.fund.roda_identifier_fragment}-#{@report.organisation.beis_organisation_reference}_transactions_upload.csv"

    stream_csv_download(filename: filename, headers: csv_headers) do |csv|
      reportable_activities.each do |activity|
        csv << csv_row(activity)
      end
    end
  end

  def update
    @report_presenter = ReportPresenter.new(@report)
    upload = CsvFileUpload.new(params[:report], :transaction_csv)
    @success = false

    if upload.valid?
      importer = ImportTransactions.new(report: @report, uploader: current_user)
      importer.import(upload.rows)
      @errors = importer.errors

      if @errors.empty?
        @success = true
        flash.now[:notice] = t("action.transaction.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.transaction.upload.file_missing_or_invalid")
    end
  end

  private def authorize_report
    @report = Report.find(params[:report_id])
    authorize @report, :show?
  end

  private def csv_headers
    ["Activity Name", "Activity Delivery Partner Identifier"] + ImportTransactions.column_headings
  end

  private def csv_row(activity)
    [
      activity.title,
      activity.delivery_partner_identifier,
      activity.roda_identifier,
      @report.financial_quarter.to_s,
      @report.financial_year.to_s,
    ]
  end

  def reportable_activities
    @report.reportable_activities.hierarchically_grouped_projects
  end
end
