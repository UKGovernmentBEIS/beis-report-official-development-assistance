class Export::SpendingBreakdown
  ACTIVITY_ATTRIBUTES = [
    :roda_identifier,
    :delivery_partner_identifier,
    :title,
    :level,
    :programme_status,
  ]

  def initialize(source_fund:, organisation: nil)
    @organisation = organisation
    @source_fund = source_fund
    @activities = activities

    @activity_attributes =
      Export::ActivityAttributesColumns.new(activities: @activities, attributes: ACTIVITY_ATTRIBUTES)
    @delivery_partner_organisations =
      Export::ActivityDeliveryPartnerOrganisationColumn.new(activities_relation: @activities)
    @actual_columns =
      Export::ActivityActualsColumns.new(activities: @activities, include_breakdown: true)
  end

  def headers
    return @activity_attributes.headers if @actual_columns.rows.empty? && forecasts.empty?

    @activity_attributes.headers +
      @delivery_partner_organisations.headers +
      @actual_columns.headers +
      forecasts_headers
  end

  def rows
    return [] if @actual_columns.rows.empty? && forecasts.empty?
    activities.map do |activity|
      @activity_attributes.rows.fetch(activity.id, nil) +
        @delivery_partner_organisations.rows.fetch(activity.id, nil) +
        @actual_columns.rows.fetch(activity.id, nil) +
        forecast_data(activity)
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

  def forecast_data(activity)
    all_forecast_financial_quarter_range.map { |fq| forecasts_to_hash.fetch([activity.id, fq.quarter, fq.financial_year.start_year], 0) }
  end

  def forecasts_to_hash
    @_forecasts_to_hash ||= forecasts.each_with_object({}) { |forecast, hash|
      hash[[forecast.parent_activity_id, forecast.financial_quarter, forecast.financial_year]] = forecast.value
    }
  end

  def activities
    @_activities ||= if @organisation.nil?
      Activity.where(source_fund_code: @source_fund.id).includes(:organisation)
    else
      Activity.includes(:organisation).where(organisation_id: @organisation.id, source_fund_code: @source_fund.id)
        .or(Activity.includes(:organisation).where(extending_organisation_id: @organisation.id, source_fund_code: @source_fund.id))
    end
  end

  def forecasts
    overview = ForecastOverview.new(activity_ids)
    @_forecasts ||= overview.latest_values
  end

  def activity_ids
    activities.pluck(:id)
  end

  def all_financial_quarters_with_forecasts
    return [] unless forecasts.present?
    forecasts.map(&:own_financial_quarter).uniq
  end

  def forecasts_headers
    all_forecast_financial_quarter_range.map do |financial_quarter|
      "Forecast #{financial_quarter}"
    end
  end

  def all_forecast_financial_quarter_range
    @_forecast_quarter_range ||= begin
      return [] if all_financial_quarters_with_forecasts.blank?

      Range.new(@actual_columns.last_financial_quarter.succ, all_financial_quarters_with_forecasts.max)
    end
  end
end
