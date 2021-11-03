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
    @forecast_columns =
      Export::ActivityForecastColumns.new(activities: @activities, starting_financial_quarter: first_forecast_financial_quarter)
  end

  def headers
    return @activity_attributes.headers if @actual_columns.rows.empty? && @forecast_columns.rows.empty?

    @activity_attributes.headers +
      @delivery_partner_organisations.headers +
      @actual_columns.headers +
      @forecast_columns.headers
  end

  def rows
    return [] if @actual_columns.rows.empty? && @forecast_columns.rows.empty?

    activities.map do |activity|
      @activity_attributes.rows.fetch(activity.id, nil) +
        @delivery_partner_organisations.rows.fetch(activity.id, nil) +
        @actual_columns.rows.fetch(activity.id, nil) +
        @forecast_columns.rows.fetch(activity.id, nil)
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

  def first_forecast_financial_quarter
    return nil if @actual_columns.rows.empty?
    @actual_columns.last_financial_quarter.succ
  end

  def activities
    @_activities ||= if @organisation.nil?
      Activity.where(source_fund_code: @source_fund.id).includes(:organisation)
    else
      Activity.includes(:organisation).where(organisation_id: @organisation.id, source_fund_code: @source_fund.id)
        .or(Activity.includes(:organisation).where(extending_organisation_id: @organisation.id, source_fund_code: @source_fund.id))
    end
  end
end
