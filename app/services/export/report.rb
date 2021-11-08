class Export::Report
  def initialize(report:)
    @report = report
    attributes_in_order = Export::ActivityAttributesOrder.attributes_in_order

    @activity_attributes =
      Export::ActivityAttributesColumns
        .new(activities: activities, attributes: attributes_in_order)
    @implementing_organisations =
      Export::ActivityImplementingOrganisationColumn.new(activities_relation: activities)
    @delivery_partner_organisations =
      Export::ActivityDeliveryPartnerOrganisationColumn.new(activities_relation: activities)
    @change_state_column =
      Export::ActivityChangeStateColumn.new(activities: activities, report: @report)
    @actuals_columns =
      Export::ActivityActualsColumns.new(activities: activities, report: @report)
  end

  def headers
    headers = []
    headers << @activity_attributes.headers
    headers << @implementing_organisations.headers
    headers << @delivery_partner_organisations.headers
    headers << @change_state_column.headers
    headers << @actuals_columns.headers if @actuals_columns.headers.any?
    headers.flatten
  end

  def rows
    activities.map do |activity|
      row = []
      row << attribute_rows.fetch(activity.id, nil)
      row << implementing_organisations_rows.fetch(activity.id, nil)
      row << delivery_partner_organisation_rows.fetch(activity.id, nil)
      row << change_state_rows.fetch(activity.id, nil)
      row << actuals_rows.fetch(activity.id, nil) if actuals_rows.any?
      row.flatten
    end
  end

  private

  def attribute_rows
    @_attribute_rows ||= @activity_attributes.rows
  end

  def implementing_organisations_rows
    @_implementing_organisation_rows ||= @implementing_organisations.rows
  end

  def delivery_partner_organisation_rows
    @_delivery_partner_organisation_rows ||= @delivery_partner_organisations.rows
  end

  def change_state_rows
    @_change_state_rows ||= @change_state_column.rows
  end

  def actuals_rows
    @_actuals_rows ||= @actuals_columns.rows
  end

  def activities
    @activities ||= begin
      Activity::ProjectsForReportFinder.new(
        report: @report,
        scope: Activity.all
      ).call.order(:level)
    end
  end
end
