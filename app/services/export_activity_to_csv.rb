require "csv"

class ExportActivityToCsv
  attr_accessor :activity, :report

  def initialize(activity: nil, report: nil)
    @activity = activity
    @report = report
  end

  def call
    metadata_columns.values.map(&:call) +
      previous_twelve_quarter_actuals +
      next_twenty_quarter_forecasts +
      variance_columns.values.map(&:call)
  end

  def headers
    metadata_columns.keys +
      previous_twelve_quarter_actuals_headers +
      next_twenty_quarter_forecasts_headers +
      variance_columns.keys
  end

  def previous_twelve_quarter_actuals
    return [] if report.own_financial_quarter.nil?

    transaction_quarters = TransactionOverview.new(activity_presenter, report_presenter).all_quarters

    previous_report_quarters.map do |quarter|
      value = transaction_quarters.value_for(**quarter)
      "%.2f" % value
    end
  end

  def next_twenty_quarter_forecasts
    return [] if report.own_financial_quarter.nil?

    forecast_quarters = PlannedDisbursementOverview.new(activity_presenter).snapshot(report_presenter).all_quarters

    following_report_quarters.map do |quarter|
      value = forecast_quarters.value_for(**quarter)
      "%.2f" % value
    end
  end

  private def metadata_columns
    @_metadata_columns ||= {
      "RODA identifier" => -> { activity_presenter.roda_identifier },
      # RODA ID fragment
      # Parent RODA ID
      "Transparency identifier" => -> { activity_presenter.transparency_identifier },
      "BEIS identifier" => -> { activity_presenter.beis_identifier },
      "Level" => -> { activity_presenter.level },
      # Other UK DPs
      # DP 'Brand'
      "Delivery partner identifier" => -> { activity_presenter.delivery_partner_identifier },
      "Recipient region" => -> { activity_presenter.recipient_region },
      "Recipient country" => -> { activity_presenter.recipient_country },
      "Intended beneficiaries" => -> { activity_presenter.intended_beneficiaries },
      "GDI" => -> { activity_presenter.gdi },
      "GCRF Strategic Area" => -> { activity_presenter.gcrf_strategic_area },
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
      "Implementing organisations" => -> { activity_presenter.implementing_organisations },
      "Tied status" => -> { activity_presenter.tied_status_with_code },
    }
  end

  private def variance_columns
    return {} if report.own_financial_quarter.nil?

    @_variance_columns ||= {
      # Additional headers specific to export CSV =============================
      "VAR #{report_financial_quarter}" => -> { activity_presenter.variance_for_report_financial_quarter(report: report) },
      "Comment" => -> { activity_presenter.comment_for_report(report_id: report.id)&.comment },
      "Source fund" => -> { activity_presenter.source_fund&.name },
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
    ["FC", report_financial_quarter].reject(&:blank?).join(" ")
  end

  private def actuals_header
    ["ACT", report_financial_quarter].reject(&:blank?).join(" ")
  end

  def previous_report_quarters
    return [] if report.own_financial_quarter.nil?

    quarter = report.own_financial_quarter
    quarter.preceding(11) + [quarter]
  end

  def following_report_quarters
    return [] if report.own_financial_quarter.nil?

    quarter = report.own_financial_quarter
    [quarter] + quarter.following(19)
  end

  private def previous_twelve_quarter_actuals_headers
    previous_report_quarters.map { |quarter| "ACT #{quarter}" }
  end

  private def next_twenty_quarter_forecasts_headers
    following_report_quarters.map { |quarter| "FC #{quarter}" }
  end
end
