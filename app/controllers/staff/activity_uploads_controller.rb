# frozen_string_literal: true

require "csv"

class Staff::ActivityUploadsController < Staff::BaseController
  include Secured

  before_action :authorize_report

  def new
    @report_presenter = ReportPresenter.new(@report)
  end

  def show
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=activities.csv"

    response.stream.write(CSV.generate_line(csv_headers))
    response.stream.close
  end

  def update
    @report_presenter = ReportPresenter.new(@report)
    rows = parse_activities_from_upload

    if rows.blank?
      @errors = []
      flash.now[:error] = t("action.activity.upload.file_missing")
      return
    end

    importer = Activities::ImportFromCsv.new(organisation: current_user.organisation)
    importer.import(rows)
    @errors = importer.errors

    if @errors.empty?
      flash.now[:notice] = t("action.activity.upload.success")
    end
  end

  private def authorize_report
    @report = Report.find(params[:report_id])
    authorize @report, :show?
  end

  private def csv_headers
    Activities::ImportFromCsv.column_headings
  end

  private def parse_activities_from_upload
    file = params[:report]&.fetch(:activity_csv, nil)
    return nil unless file

    CSV.parse(file.read, headers: true)
  rescue
    nil
  end
end
