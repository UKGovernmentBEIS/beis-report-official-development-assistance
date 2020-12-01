require "csv"

class ExportActivityToCsv
  attr_accessor :activity, :report

  def initialize(activity: nil, report: nil)
    @activity = activity
    @report = report
  end

  def call
    [
      activity_presenter.funding_organisation_name,
      activity_presenter.transparency_identifier,
      activity_presenter.delivery_partner_identifier,
      activity_presenter.roda_identifier,
      activity_presenter.beis_id,
      activity_presenter.level,
      activity_presenter.title,
      activity_presenter.description,
      activity_presenter.objectives,
      activity_presenter.recipient_region,
      activity_presenter.recipient_country,
      activity_presenter.intended_beneficiaries,
      activity_presenter.programme_status,
      activity_presenter.planned_start_date,
      activity_presenter.actual_start_date,
      activity_presenter.planned_end_date,
      activity_presenter.actual_end_date,
      activity_presenter.call_open_date,
      activity_presenter.call_close_date,
      activity_presenter.total_applications,
      activity_presenter.total_awards,
      activity_presenter.sector_with_code,
      activity_presenter.aid_type_with_code,
      activity_presenter.tied_status_with_code,
      activity_presenter.finance_with_code,
      activity_presenter.flow_with_code,
      activity_presenter.gdi,
      activity_presenter.collaboration_type,
      activity_presenter.covid19_related,
      activity_presenter.policy_marker_gender,
      activity_presenter.policy_marker_climate_change_adaptation,
      activity_presenter.policy_marker_climate_change_mitigation,
      activity_presenter.policy_marker_biodiversity,
      activity_presenter.policy_marker_desertification,
      activity_presenter.policy_marker_disability,
      activity_presenter.policy_marker_disaster_risk_reduction,
      activity_presenter.policy_marker_nutrition,
      activity_presenter.oda_eligibility,
      activity_presenter.oda_eligibility_lead,
      activity_presenter.uk_dp_named_contact,
      activity_presenter.forecasted_total_for_report_financial_quarter(report: report),
      activity_presenter.actual_total_for_report_financial_quarter(report: report),
      activity_presenter.variance_for_report_financial_quarter(report: report),
      activity_presenter.comment_for_report(report_id: report.id)&.comment,
      activity_presenter.link_to_roda,
    ].concat(next_four_quarter_forecasts).to_csv
  end

  def headers
    report_financial_quarter = ReportPresenter.new(report).financial_quarter_and_year
    [
      "Funding organisation name",
      "Transparency identifier",
      "Delivery partner identifier",
      "RODA identifier",
      "BEIS identifier",
      "Level",
      "Title",
      "Description",
      "Aims/Objectives",
      "Recipient region",
      "Recipient country",
      "Intended beneficiaries",
      "Activity status",
      "Planned start date",
      "Actual start date",
      "Planned end date",
      "Actual end date",
      "Call open date",
      "Call close date",
      "Total applications",
      "Total awards",
      "Sector",
      "Aid type",
      "Tied status",
      "Finance type",
      "Flow",
      "GDI",
      "Collaboration type",
      "Covid-19 related research",
      "Gender",
      "Climate change - Adaptation",
      "Climate change - Mitigation",
      "Biodiversity",
      "Desertification",
      "Disability",
      "Disaster Risk Reduction",
      "Nutrition policy",
      "ODA eligibility",
      "ODA eligibility lead",
      "UK DP named contact",
      report_financial_quarter ? report_financial_quarter + " forecast" : "Forecast",
      report_financial_quarter ? report_financial_quarter + " actuals" : "Actuals",
      "Variance",
      "Comment",
      "Link to activity in RODA",
    ].concat(next_four_financial_quarters).to_csv
  end

  def next_four_quarter_forecasts
    report_presenter.next_four_financial_quarters.map do |quarter, year|
      overview = PlannedDisbursementOverview.new(activity_presenter)
      value = overview.snapshot(report_presenter).value_for(financial_quarter: quarter, financial_year: year)
      "%.2f" % value
    end
  end

  private def next_four_financial_quarters
    report_presenter.next_four_financial_quarters.map { |quarter, year| "Q#{quarter} #{year}" }
  end

  private def activity_presenter
    @activity_presenter ||= ActivityCsvPresenter.new(activity)
  end

  private def report_presenter
    @report_presenter ||= ReportPresenter.new(report)
  end
end
