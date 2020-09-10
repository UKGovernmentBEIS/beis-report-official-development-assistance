# frozen_string_literal: true

require "csv"

class Staff::TransactionUploadsController < Staff::BaseController
  include Secured

  before_action :authorize_report

  def new
    @report_presenter = ReportPresenter.new(@report)
  end

  def show
    response.headers["Content-Type"] = "text/csv"
    response.headers["Content-Disposition"] = "attachment; filename=transactions.csv"

    response.stream.write(CSV.generate_line(csv_headers))
    @report.reportable_activities.each do |activity|
      response.stream.write(CSV.generate_line(csv_row(activity)))
    end
    response.stream.close
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
      activity.description,
      activity.delivery_partner_identifier,
      activity.roda_identifier_compound,
    ]
  end
end
