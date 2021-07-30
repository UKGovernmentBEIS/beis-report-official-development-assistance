module Breadcrumbed
  extend ActiveSupport::Concern

  def prepare_default_activity_trail(activity)
    if activity.historic?
      add_breadcrumb "Historic activities", historic_organisation_activities_path(activity.organisation)
    else
      add_breadcrumb "Current activities", organisation_activities_path(activity.organisation)
    end

    if activity.third_party_project?
      add_breadcrumb activity.parent.parent.title, organisation_activity_financials_path(activity.parent.parent.organisation, activity.parent.parent)
      add_breadcrumb activity.parent.title, organisation_activity_financials_path(activity.parent.organisation, activity.parent)
    elsif activity.project?
      add_breadcrumb activity.parent.title, organisation_activity_financials_path(activity.parent.organisation, activity.parent)
    end

    add_breadcrumb activity.title, organisation_activity_financials_path(activity.organisation, activity)
  end
end
