# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured

  def index
    @organisation_id = organisation_id
    @activities = policy_scope(Activity.where(organisation: organisation_id))
    authorize @activities
    @activity_presenters = @activities.includes(:organisation).order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }
  end

  def show
    @activity = Activity.find(id)
    authorize @activity

    @activities = @activity.child_activities.order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }

    @transactions = policy_scope(Transaction).where(parent_activity: @activity).order("date DESC")
    @budgets = policy_scope(Budget).where(parent_activity: @activity).order("period_start_date DESC")
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

  def create
    @activity = CreateActivity.new(organisation_id: organisation_id).call

    authorize @activity

    @activity.create_activity key: "activity.create", owner: current_user

    redirect_to activity_step_path(@activity.id, :blank)
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
end
