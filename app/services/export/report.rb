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
  end

  def headers
    @activity_attributes.headers +
      @implementing_organisations.headers +
      @delivery_partner_organisations.headers
  end

  def rows
    activities.map do |activity|
      attribute_rows.fetch(activity.id, nil) +
        implementing_organisations_rows.fetch(activity.id, nil) +
        delivery_partner_organisation_rows.fetch(activity.id, nil)
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

  def activities
    @activities ||= begin
      Activity::ProjectsForReportFinder.new(
        report: @report,
        scope: Activity.all
      ).call.order(:level)
    end
  end
end
