# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed

  after_action :verify_authorized, except: [:index, :historic]
  after_action :skip_policy_scope, only: [:index, :historic]
  skip_before_action :clear_breadcrumb_context, only: [:show]

  def index
    @organisation = Organisation.find(organisation_id)
    if @organisation.service_owner?
      @delivery_partner_organisations = Organisation.delivery_partners

      add_breadcrumb t("page_content.breadcrumbs.activities_by_delivery_partner"), organisation_activities_path(Organisation.service_owner)

      render "staff/activities/index_beis"
    else
      @funds = Activity.fund.order(:title)
      @grouped_activities = Activity::GroupedActivitiesFetcher.new(
        user: current_user,
        organisation: @organisation,
        scope: :current
      ).call

      if current_user.service_owner?
        add_breadcrumb t("page_content.breadcrumbs.organisation_current_index", org_name: @organisation.name), organisation_activities_path(@organisation)
      else
        add_breadcrumb t("page_content.breadcrumbs.current_index"), organisation_activities_path(@organisation)
      end
    end
  end

  def show
    @activity = Activity.find(id)
    authorize @activity

    respond_to do |format|
      format.html do
        prepare_default_activity_trail(@activity)

        tab = Activity::Tab.new(
          activity: @activity,
          current_user: current_user,
          tab_name: current_tab
        )
        render template: tab.template, locals: tab.locals
      end
      format.xml do |_format|
        @activities = @activity.child_activities.order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }

        @transactions = policy_scope(Transaction).where(parent_activity: @activity).order("date DESC")
        @budgets = policy_scope(Budget).where(parent_activity: @activity).order("financial_year DESC")
        @forecasts = policy_scope(@activity.latest_forecasts)
        @reporting_organisation = Organisation.service_owner

        response.headers["Content-Disposition"] = "attachment; filename=\"#{@activity.transparency_identifier}.xml\""
      end
    end
  end

  def historic
    @organisation = Organisation.find(organisation_id)
    if @organisation.service_owner?
      @delivery_partner_organisations = Organisation.delivery_partners
      render "staff/activities/index_beis"
    else
      @grouped_activities = Activity::GroupedActivitiesFetcher.new(
        user: current_user,
        organisation: @organisation,
        scope: :historic
      ).call

      if current_user.service_owner?
        add_breadcrumb t("page_content.breadcrumbs.organisation_historic_index", org_name: @organisation.name), historic_organisation_activities_path(@organisation)
      else
        add_breadcrumb t("page_content.breadcrumbs.historic_index"), historic_organisation_activities_path(@organisation)
      end
    end
  end

  private

  def id
    params[:id] || params[:activity_id]
  end

  def organisation_id
    organisation_id = params.fetch(:organisation_id, current_user.organisation).to_s

    return current_user.organisation.id unless Organisation.exists?(organisation_id)
    return current_user.organisation.id if organisation_id.blank?
    return current_user.organisation.id if requested_organisation_is_not_current_users?(organisation_id) && current_user.delivery_partner?
    organisation_id
  end

  def requested_organisation_is_not_current_users?(requested_organisation_id)
    requested_organisation_id != current_user.organisation.id
  end

  def fund_id
    params[:fund_id]
  end

  def current_tab
    params[:tab] || "financials"
  end
end
