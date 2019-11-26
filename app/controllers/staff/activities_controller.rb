# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured

  def index
    @activities = policy_scope(Activity)
    authorize @activities
  end

  def show
    activity = policy_scope(Activity).find(id)
    authorize activity

    @activity_presenter = ActivityPresenter.new(activity)
  end

  def new
    @activity = policy_scope(Activity).new
    authorize @activity
  end

  def create
    @activity = policy_scope(Activity).new(activity_params)
    authorize @activity

    hierarchy = policy_scope(Fund).find(activity_params[:hierarchy_id])
    @activity.hierarchy = hierarchy

    if @activity.valid?
      @activity.save
      flash[:notice] = I18n.t("form.activity.create.success")
      redirect_to activity_path(@activity)
    else
      render :new
    end
  end

  private

  def activity_params
    params.require(:activity).permit(:identifier, :sector, :title, :description, :status,
      :planned_start_date_day, :planned_start_date_month, :planned_start_date_year,
      :planned_end_date_day, :planned_end_date_month, :planned_end_date_year,
      :actual_start_date_day, :actual_start_date_month, :actual_start_date_year,
      :actual_end_date_day, :actual_end_date_month, :actual_end_date_year,
      :recipient_region, :flow, :finance, :aid_type, :tied_status,
      :hierarchy_id, :fund_id)
  end

  def id
    params[:id]
  end
end
