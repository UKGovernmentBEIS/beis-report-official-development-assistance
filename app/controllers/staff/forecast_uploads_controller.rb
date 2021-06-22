# frozen_string_literal: true

require "csv"

class Staff::ForecastUploadsController < Staff::BaseController
  include Secured
  include StreamCsvDownload

  def new
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
  end

  def show
    authorize report, :show?

    @report_presenter = ReportPresenter.new(report)
    generator = ImportForecasts::Generator.new(report)
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
    upload = CsvFileUpload.new(params[:report], :forecast_csv)
    @success = false

    if upload.valid?
      importer = ImportForecasts.new(uploader: current_user)
      importer.import(upload.rows)
      @errors = importer.errors

      if @errors.empty?
        imported_forecasts = importer.imported_forecasts.compact
        @grouped_forecasts = imported_forecasts
          .map { |forecast| ForecastPresenter.new(forecast) }
          .group_by { |forecast| ActivityPresenter.new(forecast.parent_activity) }
        @total_forecast = TotalPresenter.new(imported_forecasts.sum(&:value)).value
        @success = true
        flash.now[:notice] = t("action.forecast.upload.success")
      end
    else
      @errors = []
      flash.now[:error] = t("action.forecast.upload.file_missing_or_invalid")
    end
  end

  private def report
    @_report ||= Report.find(params[:report_id])
  end
end
