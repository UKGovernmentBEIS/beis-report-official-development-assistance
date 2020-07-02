# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured

  def index
    @activities = policy_scope(Activity)
  end

  def show
    @activity = Activity.find(id)
    authorize @activity

    @activities = @activity.child_activities.order("created_at ASC").map { |activity| ActivityPresenter.new(activity) }

    @transactions = policy_scope(Transaction).where(parent_activity: @activity).order("date DESC")
    @budgets = policy_scope(Budget).where(parent_activity: @activity).order("period_start_date DESC")
    @planned_disbursements = policy_scope(PlannedDisbursement).where(parent_activity: @activity).order("period_start_date DESC")

    respond_to do |format|
      format.html do
        redirect_to organisation_activity_financials_path(@activity.organisation, @activity)
      end
      format.xml do |_format|
        @activity_xml_presenter = ActivityXmlPresenter.new(@activity)
        response.headers["Content-Disposition"] = "attachment; filename=\"#{@activity_xml_presenter.iati_identifier}.xml\""
      end
    end
  end

  def create
    raise NotImplementedError
  end

  private

  def id
    params[:id]
  end

  def organisation_id
    params[:organisation_id]
  end

  def fund_id
    params[:fund_id]
  end
end
