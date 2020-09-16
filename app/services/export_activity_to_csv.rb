require "csv"

class ExportActivityToCsv
  attr_accessor :activity, :report

  def initialize(activity: nil, report: nil)
    @activity = activity
    @report = report
  end

  def call
    [
      activity_presenter.delivery_partner_identifier,
      activity_presenter.transparency_identifier,
      activity_presenter.sector_with_code,
      activity_presenter.title,
      activity_presenter.description,
      activity_presenter.programme_status,
      activity_presenter.planned_start_date,
      activity_presenter.actual_start_date,
      activity_presenter.planned_end_date,
      activity_presenter.actual_end_date,
      activity_presenter.recipient_region,
      activity_presenter.recipient_country,
      activity_presenter.aid_type_with_code,
      activity_presenter.level,
      activity_presenter.actual_total_for_report_financial_quarter(report: report),
      activity_presenter.forecasted_total_for_report_financial_quarter(report: report),
      activity_presenter.variance_for_report_financial_quarter(report: report),
      activity_presenter.comment_for_report(report_id: report.id)&.comment,
      activity_presenter.link_to_roda,
    ].concat(next_four_quarter_forecasts).to_csv
  end

  def headers
    report_financial_quarter = ReportPresenter.new(report).financial_quarter_and_year
    [
      "Identifier",
      "Transparency identifier",
      "Sector",
      "Title",
      "Description",
      "Programme status",
      "Planned start date",
      "Actual start date",
      "Planned end date",
      "Actual end date",
      "Recipient region",
      "Recipient country",
      "Aid type",
      "Level",
      report_financial_quarter ? report_financial_quarter + " actuals" : "Actuals",
      report_financial_quarter ? report_financial_quarter + " forecast" : "Forecast",
      "Variance",
      "Comment",
      "Link to activity in RODA",
    ].concat(report_presenter.next_four_financial_quarters).to_csv
  end

  def next_four_quarter_forecasts
    quarter_date_ranges = report_presenter.quarters_to_date_ranges
    quarter_date_ranges.map { |range| activity_presenter.forecasted_total_for_date_range(range: range) }
  end

  private def activity_presenter
    @activity_presenter ||= ActivityPresenter.new(activity)
  end

  private def report_presenter
    @report_presenter ||= ReportPresenter.new(report)
  end
end
