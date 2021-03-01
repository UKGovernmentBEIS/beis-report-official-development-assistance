require "csv"

class ExportActivityToCsv
  attr_accessor :activity, :report

  def initialize(activity: nil, report: nil)
    @activity = activity
    @report = report
  end

  def call
    values = columns.values.map(&:call)
    values = values.push(previous_quarter_actuals) if previous_report.present?
    values = values.concat(next_twelve_quarter_forecasts)
    values
  end

  def headers
    values = columns.keys
    values = values.push(previous_quarter_actuals_header) if previous_report.present?
    values = values.concat(next_twelve_quarter_forecasts_headers)
    values
  end

  def previous_quarter_actuals
    activity_presenter.actual_total_for_report_financial_quarter(report: previous_report)
  end

  def next_twelve_quarter_forecasts
    report_presenter.next_twelve_financial_quarters.map do |quarter, year|
      overview = PlannedDisbursementOverview.new(activity_presenter)
      value = overview.snapshot(report_presenter).value_for(financial_quarter: quarter, financial_year: year)
      "%.2f" % value
    end
  end

  private def columns
    @_columns ||= {
      "RODA identifier" => -> { activity_presenter.roda_identifier },
      # RODA ID fragment
      # Parent RODA ID
      "Transparency identifier" => -> { activity_presenter.transparency_identifier },
      "BEIS identifier" => -> { activity_presenter.beis_id },
      "Level" => -> { activity_presenter.level },
      # Other UK DPs
      # DP 'Brand'
      "Delivery partner identifier" => -> { activity_presenter.delivery_partner_identifier },
      "Recipient region" => -> { activity_presenter.recipient_region },
      "Recipient country" => -> { activity_presenter.recipient_country },
      "Intended beneficiaries" => -> { activity_presenter.intended_beneficiaries },
      "GDI" => -> { activity_presenter.gdi },
      "GCRF Challenge Area" => -> { activity_presenter.gcrf_challenge_area },
      "Fund Pillar" => -> { activity_presenter.fund_pillar },
      "SDG 1" => -> { activity_presenter.sdg_1 },
      "SDG 2" => -> { activity_presenter.sdg_2 },
      "SDG 3" => -> { activity_presenter.sdg_3 },
      "Title" => -> { activity_presenter.title },
      # DFID Activity Title
      "Description" => -> { activity_presenter.description },
      # DFID Activity Description
      "Aims/Objectives" => -> { activity_presenter.objectives },
      "ODA eligibility" => -> { activity_presenter.oda_eligibility },
      "ODA eligibility lead" => -> { activity_presenter.oda_eligibility_lead },
      "Covid-19 related research" => -> { activity_presenter.covid19_related },
      "Activity status" => -> { activity_presenter.programme_status },
      "Country delivery partners" => -> { activity_presenter.country_delivery_partners },
      "UK DP named contact" => -> { activity_presenter.uk_dp_named_contact },
      "Call open date" => -> { activity_presenter.call_open_date },
      "Call close date" => -> { activity_presenter.call_close_date },
      "Planned start date" => -> { activity_presenter.planned_start_date },
      "Actual start date" => -> { activity_presenter.actual_start_date },
      "Planned end date" => -> { activity_presenter.planned_end_date },
      "Actual end date" => -> { activity_presenter.actual_end_date },
      "Total applications" => -> { activity_presenter.total_applications },
      "Total awards" => -> { activity_presenter.total_awards },
      # Total applications to Newton Fund partner DP
      # Total awards by NF partner DP
      "Sector" => -> { activity_presenter.sector_with_code },
      "Channel of delivery code" => -> { activity_presenter.channel_of_delivery_code },
      "Flow" => -> { activity_presenter.flow_with_code },
      "Finance type" => -> { activity_presenter.finance_with_code },
      "Aid type" => -> { activity_presenter.aid_type_with_code },
      "Collaboration type" => -> { activity_presenter.collaboration_type },
      "Gender" => -> { activity_presenter.policy_marker_gender },
      "Climate change - Adaptation" => -> { activity_presenter.policy_marker_climate_change_adaptation },
      "Climate change - Mitigation" => -> { activity_presenter.policy_marker_climate_change_mitigation },
      "Biodiversity" => -> { activity_presenter.policy_marker_biodiversity },
      "Desertification" => -> { activity_presenter.policy_marker_desertification },
      "Disability" => -> { activity_presenter.policy_marker_disability },
      "Free Standing Technical Cooperation" => -> { activity_presenter.fstc_applies },
      "Disaster Risk Reduction" => -> { activity_presenter.policy_marker_disaster_risk_reduction },
      "Nutrition policy" => -> { activity_presenter.policy_marker_nutrition },
      # Implementing organisation name
      # Implementing organisation reference
      # Implementing organisation sector
      "Tied status" => -> { activity_presenter.tied_status_with_code },

      # Additional headers specific to export CSV =============================
      forecast_header => -> { activity_presenter.forecasted_total_for_report_financial_quarter(report: report) },
      actuals_header => -> { activity_presenter.actual_total_for_report_financial_quarter(report: report) },
      "Variance" => -> { activity_presenter.variance_for_report_financial_quarter(report: report) },
      "Comment" => -> { activity_presenter.comment_for_report(report_id: report.id)&.comment },
      "Link to activity in RODA" => -> { activity_presenter.link_to_roda },
    }
  end

  private def activity_presenter
    @activity_presenter ||= ActivityCsvPresenter.new(activity)
  end

  private def report_presenter
    @report_presenter ||= ReportPresenter.new(report)
  end

  private def report_financial_quarter
    report_presenter.financial_quarter_and_year
  end

  private def forecast_header
    report_financial_quarter ? report_financial_quarter + " forecast" : "Forecast"
  end

  private def actuals_header
    report_financial_quarter ? report_financial_quarter + " actuals" : "Actuals"
  end

  private def previous_report
    @_previous_report ||= report.previous
  end

  private def previous_report_presenter
    @previous_report_presenter ||= ReportPresenter.new(previous_report)
  end

  private def previous_quarter_actuals_header
    "#{previous_report_presenter.financial_quarter_and_year} actuals"
  end

  private def next_twelve_quarter_forecasts_headers
    report_presenter.next_twelve_financial_quarters.map { |quarter, year| "Q#{quarter} #{year}" }
  end
end
