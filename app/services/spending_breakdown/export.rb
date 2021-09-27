class SpendingBreakdown::Export
  HEADERS = [
    "RODA identifier",
    "Delivery partner identifier",
    "Delivery partner organisation",
    "Title",
    "Level",
    "Activity status",
  ]

  def initialize(source_fund:, organisation: nil)
    @organisation = organisation
    @source_fund = source_fund
  end

  def headers
    return HEADERS if actuals.empty? && refunds.empty? && forecasts.empty?

    HEADERS + headers_from_financial_quarters + forecasts_headers
  end

  def rows
    activities.map do |activity|
      activity_data(activity) + financial_data(activity) + forecast_data(activity)
    end
  end

  def filename
    [
      @source_fund.short_name,
      @organisation&.beis_organisation_reference,
      "spending_breakdown.csv",
    ].reject(&:blank?).join("_")
  end

  private

  def financial_data(activity)
    build_row(all_totals_for_activity(activity), activity)
  end

  def forecast_data(activity)
    all_forecast_financial_quarter_range.map { |fq| forecasts_to_hash.fetch([activity.id, fq.quarter, fq.financial_year.start_year], 0) }
  end

  def forecasts_to_hash
    @_forecasts_to_hash ||= forecasts.each_with_object({}) { |forecast, hash|
      hash[[forecast.parent_activity_id, forecast.financial_quarter, forecast.financial_year]] = forecast.value
    }
  end

  def all_totals_for_activity(activity)
    Transaction.joins("LEFT OUTER JOIN adjustment_details ON adjustment_details.adjustment_id = transactions.id")
      .where(parent_activity_id: activity.id)
      .select(:financial_quarter, :financial_year, :parent_activity_id, :value, :type, "adjustment_details.adjustment_type")
      .group(:parent_activity_id, :financial_quarter, :financial_year, :type, "adjustment_details.adjustment_type")
      .order(:parent_activity_id, :financial_quarter, :financial_year)
      .sum(:value)
  end

  def build_row(totals, activity)
    rows = financial_quarter_range.map { |fq|
      actual_overview = TransactionOverview.new(:actual, activity, totals, fq)
      refund_overview = TransactionOverview.new(:refund, activity, totals, fq)

      net_total = actual_overview.net_total + refund_overview.net_total

      [actual_overview.net_total, refund_overview.net_total, net_total]
    }
    rows.flatten!
  end

  def activity_data(activity)
    [
      activity.roda_identifier,
      activity.delivery_partner_identifier,
      activity.organisation.name,
      activity.title,
      I18n.t("table.body.activity.level.#{activity.level}"),
      I18n.t("activity.programme_status.#{activity.programme_status}"),
    ]
  end

  def activities
    @_activities ||= if @organisation.nil?
      Activity.where(source_fund_code: @source_fund.id).includes(:organisation)
    else
      Activity.includes(:organisation).where(organisation_id: @organisation.id, source_fund_code: @source_fund.id)
        .or(Activity.includes(:organisation).where(extending_organisation_id: @organisation.id, source_fund_code: @source_fund.id))
    end
  end

  def actuals
    @_actuals ||= Actual.where(parent_activity_id: activity_ids)
  end

  def refunds
    @_refunds ||= Refund.where(parent_activity_id: activity_ids)
  end

  def forecasts
    overview = ForecastOverview.new(activity_ids)
    @_forecasts ||= overview.latest_values
  end

  def activity_ids
    activities.pluck(:id)
  end

  def financial_quarters_with_acutals
    return [] unless actuals.present?
    actuals.map(&:own_financial_quarter).uniq
  end

  def financial_quarters_with_refunds
    return [] unless refunds.present?
    refunds.map(&:own_financial_quarter).uniq
  end

  def all_financial_quarters_with_forecasts
    return [] unless forecasts.present?
    forecasts.map(&:own_financial_quarter).uniq
  end

  def financial_quarters
    financial_quarters_with_acutals + financial_quarters_with_refunds
  end

  def actual_and_refund_headers
    all_actual_and_refund_financial_quarter_range.map { |financial_quarter|
      [
        "Actual spend #{financial_quarter}",
        "Refund #{financial_quarter}",
        "Actual net #{financial_quarter}",
      ]
    }.flatten!
  end

  def forecasts_headers
    all_forecast_financial_quarter_range.map do |financial_quarter|
      "Forecast #{financial_quarter}"
    end
  end

  def financial_quarter_range
    @_financial_quarter_range ||= Range.new(*financial_quarters.minmax)
  end

  def all_forecast_financial_quarter_range
    @_forecast_quarter_range ||= Range.new(financial_quarter_range.last.succ, *all_financial_quarters_with_forecasts.max)
  end

  class TransactionOverview
    TRANSACTION_TYPES = {
      actual: "Actual",
      refund: "Refund",
    }

    def initialize(transaction_type, activity, totals, financial_quarter)
      @transaction_type = TRANSACTION_TYPES[transaction_type]
      @activity = activity
      @totals = totals
      @financial_quarter = financial_quarter
    end

    def net_total
      total + adjustments_total
    end

    private

    def total
      @totals.fetch([@activity.id, @financial_quarter.quarter, @financial_quarter.financial_year.start_year, @transaction_type, nil], 0)
    end

    def adjustments_total
      @totals.fetch([@activity.id, @financial_quarter.quarter, @financial_quarter.financial_year.start_year, "Adjustment", @transaction_type], 0)
    end
  end
end
