class Export::Report
  def initialize(report:)
    @report = report
    attributes_in_order = report.for_ispf? ?
      Export::IspfActivityAttributesOrder.attributes_in_order : Export::NonIspfActivityAttributesOrder.attributes_in_order

    @activity_attributes =
      Export::ActivityAttributesColumns
        .new(activities: activities, attributes: attributes_in_order)
    @implementing_organisations =
      Export::ActivityImplementingOrganisationColumn.new(activities_relation: activities)
    @partner_organisations =
      Export::ActivityPartnerOrganisationColumn.new(activities_relation: activities)
    @change_state_column =
      Export::ActivityChangeStateColumn.new(activities: activities, report: @report)
    @commitment_column =
      Export::ActivityCommitmentColumn.new(activities: activities.includes([:commitment]))
    @actuals_columns =
      Export::ActivityActualsColumns.new(activities: activities, report: @report)
    @forecast_columns =
      Export::ActivityForecastColumns.new(activities: activities, report: @report)
    @variance_column =
      Export::ActivityVarianceColumn.new(
        activities: activities,
        net_actual_spend_column_data: @actuals_columns.rows_for_last_financial_quarter,
        forecast_column_data: @forecast_columns.rows_for_first_financial_quarter,
        financial_quarter: @report.own_financial_quarter
      )
    @comments_column =
      Export::ActivityCommentsColumn.new(
        activities: activities,
        report: @report
      )
    @tags_column = Export::ActivityTagsColumn.new(activities: activities) if @report.for_ispf?
    @link_column = Export::ActivityLinkColumn.new(activities: activities)
    @iati_column = Export::ActivityIatiColumn.new(activities: activities)
  end

  def headers
    headers = []
    headers << @activity_attributes.headers
    headers << @implementing_organisations.headers
    headers << @partner_organisations.headers
    headers << @change_state_column.headers
    headers << @commitment_column.headers
    headers << @actuals_columns.headers if @actuals_columns.headers.any?
    headers << @variance_column.headers if @actuals_columns.headers.any? && @forecast_columns.headers.any?
    headers << @forecast_columns.headers if @forecast_columns.headers.any?
    headers << @comments_column.headers
    headers << @tags_column.headers if @report.for_ispf?
    headers << @link_column.headers
    headers << @iati_column.headers
    headers.flatten
  end

  def rows
    activities.map do |activity|
      row = []
      row << attribute_rows.fetch(activity.id, nil)
      row << implementing_organisations_rows.fetch(activity.id, nil)
      row << partner_organisation_rows.fetch(activity.id, nil)
      row << change_state_rows.fetch(activity.id, nil)
      row << commitment_rows.fetch(activity.id, nil)
      row << actuals_rows.fetch(activity.id, nil) if @actuals_columns.headers.any?
      row << variance_rows.fetch(activity.id, nil) if @actuals_columns.headers.any? && @forecast_columns.headers.any?
      row << forecast_rows.fetch(activity.id, nil) if @forecast_columns.headers.any?
      row << comment_rows.fetch(activity.id, nil)
      row << tags_rows.fetch(activity.id, nil) if @report.for_ispf?
      row << link_rows.fetch(activity.id, nil)
      row << iati_rows.fetch(activity.id, nil)
      row.flatten
    end
  end

  def filename
    [
      @report.own_financial_quarter,
      @report.fund.source_fund.short_name,
      @report.is_oda.nil? ? nil : I18n.t(".is_oda_summary.#{@report.is_oda}"),
      @report.organisation.beis_organisation_reference,
      "report.csv"
    ].reject(&:blank?).join("_")
  end

  private

  def attribute_rows
    @_attribute_rows ||= @activity_attributes.rows
  end

  def implementing_organisations_rows
    @_implementing_organisation_rows ||= @implementing_organisations.rows
  end

  def partner_organisation_rows
    @_partner_organisation_rows ||= @partner_organisations.rows
  end

  def change_state_rows
    @_change_state_rows ||= @change_state_column.rows
  end

  def commitment_rows
    @_commitment_rows ||= @commitment_column.rows
  end

  def actuals_rows
    @_actuals_rows ||= @actuals_columns.rows
  end

  def forecast_rows
    @_forecast_rows ||= @forecast_columns.rows
  end

  def variance_rows
    @_variance_rows ||= @variance_column.rows
  end

  def comment_rows
    @_comment_rows ||= @comments_column.rows
  end

  def tags_rows
    @_tags_rows ||= @tags_column.rows
  end

  def link_rows
    @_link_rows ||= @link_column.rows
  end

  def iati_rows
    @_iati_rows ||= @iati_column.rows
  end

  def activities
    @activities ||= Activity::ProjectsForReportFinder.new(
      report: @report,
      scope: Activity.all
    ).call.order(level: :asc)
  end
end
