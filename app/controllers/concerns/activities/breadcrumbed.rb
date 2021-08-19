module Activities
  module Breadcrumbed
    extend ActiveSupport::Concern
    include Reports::Breadcrumbed
    include Searches::Breadcrumbed

    def prepare_default_activity_trail(activity)
      return if activity.fund? && !current_user.service_owner?

      if breadcrumb_context.type == :report
        # If we've come here from a report - show the report breadcrumb
        prepare_default_report_trail(breadcrumb_context.model)
      elsif breadcrumb_context.type == :search
        # If we've come from a search query - show the search breadcrumb
        prepare_default_search_trail(breadcrumb_context.model)
      elsif current_user.service_owner? && (activity.fund? || activity.programme?)
        # Show fund/programme breadcrumbs (these don't belong to an organisation)
        add_breadcrumb activity.parent.title, organisation_activity_financials_path(activity.parent.organisation, activity.parent) if activity.parent
        add_breadcrumb activity.title, organisation_activity_financials_path(activity.organisation, activity)

        return
      elsif activity.historic?
        # Show historic index path
        add_breadcrumb index_crumb_title(activity), historic_organisation_activities_path(activity.organisation)
      else
        # Show current index path
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

    def breadcrumb_context
      @breadcrumb_context ||= BreadcrumbContext.new(session)
    end
  end
end
