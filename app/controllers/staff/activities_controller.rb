# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured
  after_action :verify_authorized, except: [:index, :historic]
  after_action :verify_policy_scoped, only: [:index, :historic]

  def index
    @organisation = Organisation.find(organisation_id)
    @grouped_programmes = fetch_grouped_programmes_for(@organisation, :current)
  end

  def show
    @activity = Activity.find(id)
    authorize @activity

    @activities = @activity.child_activities.order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }

    @transactions = policy_scope(Transaction).where(parent_activity: @activity).order("date DESC")
    @budgets = policy_scope(Budget).where(parent_activity: @activity).order("financial_year DESC")
    @planned_disbursements = policy_scope(@activity.latest_planned_disbursements)

    respond_to do |format|
      format.html do
        redirect_to organisation_activity_financials_path(@activity.organisation, @activity)
      end
      format.xml do |_format|
        response.headers["Content-Disposition"] = "attachment; filename=\"#{@activity.transparency_identifier}.xml\""
      end
    end
  end

  def historic
    @organisation = Organisation.find(organisation_id)
    @grouped_programmes = fetch_grouped_programmes_for(@organisation, :historic)
  end

  private

  def id
    params[:id]
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

  def fetch_grouped_programmes_for(organisation, scope)
    activities = policy_scope(
      Activity.includes(
        :organisation,
        parent: [:parent, :organisation],
        child_activities: [:child_activities, :organisation, :parent]
      ).programme
       .send(scope)
    )
    unless organisation.service_owner?
      activities = activities.where(extending_organisation: organisation)
    end
    activities.order(:roda_identifier_compound)
      .group_by(&:parent)
  end
end
