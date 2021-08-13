module Breadcrumbed
  extend ActiveSupport::Concern

  def prepare_default_activity_trail(activity)
    return if activity.fund? && !current_user.service_owner?

    if activity.fund?
      add_breadcrumb activity.title, organisation_activity_financials_path(activity.organisation, activity)
      return
    elsif activity.programme? && current_user.service_owner?
      add_breadcrumb activity.parent.title, organisation_activity_financials_path(activity.parent.organisation, activity.parent)
      add_breadcrumb activity.title, organisation_activity_financials_path(activity.organisation, activity)
      return
    end

    # index crumb section
    if activity.historic?
      add_breadcrumb index_crumb_title(activity), historic_organisation_activities_path(activity.organisation)
    else
      add_breadcrumb index_crumb_title(activity), organisation_activities_path(activity.organisation)
    end

    # activity parent tree section
    if activity.third_party_project?
      add_breadcrumb activity.parent.parent.title, organisation_activity_financials_path(activity.parent.parent.organisation, activity.parent.parent)
      add_breadcrumb activity.parent.title, organisation_activity_financials_path(activity.parent.organisation, activity.parent)
    elsif activity.project?
      add_breadcrumb activity.parent.title, organisation_activity_financials_path(activity.parent.organisation, activity.parent)
    end

    # "leaf" activity section
    add_breadcrumb activity.title, organisation_activity_financials_path(activity.organisation, activity)
  end

  def index_crumb_title(activity)
    if activity.historic? && current_user.service_owner?
      t("page_content.breadcrumbs.organisation_historic_index", org_name: activity.organisation.name)
    elsif activity.historic?
      t("page_content.breadcrumbs.historic_index")
    elsif current_user.service_owner?
      t("page_content.breadcrumbs.organisation_current_index", org_name: activity.organisation.name)
    else
      t("page_content.breadcrumbs.current_index")
    end
  end
end
