# frozen_string_literal: true

require "csv"

class Staff::PlannedDisbursementUploadsController < Staff::BaseController
  include Secured

  before_action :authorize_report

  def new
    @report_presenter = ReportPresenter.new(@report)
  end

  def show
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=forecasts.csv"

    generator = ImportPlannedDisbursements::Generator.new

    response.stream.write(CSV.generate_line(generator.column_headings))
    @report.reportable_activities.each do |activity|
      response.stream.write(CSV.generate_line(generator.csv_row(activity)))
    end
    response.stream.close
  end

  def update
    @report_presenter = ReportPresenter.new(@report)
    rows = parse_planned_disbursements_from_upload

    if rows.nil?
      @errors = []
      flash.now[:error] = t("action.planned_disbursement.upload.file_missing")
      return
    end

    importer = ImportPlannedDisbursements.new(uploader: current_user)
    importer.import(rows)
    @errors = importer.errors

    if @errors.empty?
      flash.now[:notice] = t("action.planned_disbursement.upload.success")
    end
  end

  private def authorize_report
    @report = Report.find(params[:report_id])
    authorize @report, :show?
  end

  private def parse_planned_disbursements_from_upload
    file = params[:report]&.fetch(:planned_disbursement_csv, nil)
    return nil unless file

    CSV.parse(file.read, headers: true)
  rescue
    nil
  end
end
