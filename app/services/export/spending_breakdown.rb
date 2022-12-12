class Export::SpendingBreakdown
  ACTIVITY_ATTRIBUTES = [
    :roda_identifier,
    :partner_organisation_identifier,
    :title,
    :level,
    :programme_status
  ]

  def initialize(source_fund:, organisation: nil)
    @organisation = organisation
    @source_fund = source_fund
    @is_ispf = source_fund.ispf?
    @activities = activities

    @activity_attributes =
      Export::ActivityAttributesColumns.new(activities: @activities, attributes: ACTIVITY_ATTRIBUTES)
    @partner_organisations =
      Export::ActivityPartnerOrganisationColumn.new(activities_relation: @activities)
    @actual_columns =
      Export::ActivityActualsColumns.new(activities: @activities, include_breakdown: true)
    @forecast_columns =
      Export::ActivityForecastColumns.new(activities: @activities, starting_financial_quarter: first_forecast_financial_quarter)
    @tags = Export::ActivityTagsColumn.new(activities: @activities) if @is_ispf
  end

  def headers
    return @activity_attributes.headers if actuals_rows.empty? && forecast_rows.empty?

    headers = @activity_attributes.headers +
      @partner_organisations.headers +
      @actual_columns.headers +
      @forecast_columns.headers

    headers += @tags.headers if @is_ispf

    headers
  end

  def rows
    return [] if actuals_rows.empty? && forecast_rows.empty?

    attribute_row_data = @activity_attributes.rows
    partner_organisations_row_data = @partner_organisations.rows
    tags_row_data = @tags.rows if @is_ispf

    activities.map do |activity|
      row = attribute_row_data.fetch(activity.id, nil) +
        partner_organisations_row_data.fetch(activity.id, nil) +
        actuals_rows.fetch(activity.id, nil) +
        forecast_rows.fetch(activity.id, nil)

      row += tags_row_data.fetch(activity.id, nil) if @is_ispf

      row
    end
  end

  def filename
    [
      @source_fund.short_name,
      @organisation&.beis_organisation_reference,
      "spending_breakdown.csv"
    ].reject(&:blank?).join("_")
  end

  private

  def actuals_rows
    @_actuals_rows ||= @actual_columns.rows
  end

  def forecast_rows
    @_forecast_rows ||= @forecast_columns.rows
  end

  def first_forecast_financial_quarter
    return nil if actuals_rows.empty?
    return nil if @actual_columns.last_financial_quarter.nil?
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
