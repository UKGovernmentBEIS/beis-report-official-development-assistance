# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured
  include ActivityHelper

  def show
    @activity = policy_scope(Activity).find(id)
    authorize @activity

    @activity_presenter = ActivityPresenter.new(@activity)

    respond_to do |format|
      format.html
      format.xml
    end
  end

  def new
    @activity = policy_scope(Activity).new
    authorize @activity

    @fund = Fund.find params["fund_id"]
  end

  def create
    @activity = policy_scope(Activity).new(activity_params)
    authorize @activity

    @fund = policy_scope(Fund).find(activity_params[:hierarchy_id])
    @activity.hierarchy = @fund

    @activity.planned_start_date = format_date(planned_start_date)
    @activity.planned_end_date = format_date(planned_end_date)
    @activity.actual_start_date = format_date(actual_start_date)
    @activity.actual_end_date = format_date(actual_end_date)

    if @activity.valid?
      @activity.save
      flash[:notice] = I18n.t("form.activity.create.success")
      redirect_to activity_path_for(@activity)
    else
      render :new
    end
  end

  private

  def format_date(params)
    date_parts = params.values_at(:day, :month, :year)
    return unless date_parts.all?(&:present?)

    day, month, year = date_parts.map(&:to_i)
    Date.new(year, month, day)
  end

  def planned_start_date
    params.require(:planned_start_date).permit(:day, :month, :year)
  end

  def planned_end_date
    params.require(:planned_end_date).permit(:day, :month, :year)
  end

  def actual_start_date
    params.require(:actual_start_date).permit(:day, :month, :year)
  end

  def actual_end_date
    params.require(:actual_end_date).permit(:day, :month, :year)
  end

  def activity_params
    params.require(:activity).permit(:identifier, :sector, :title, :description, :status,
      :recipient_region, :flow, :finance, :aid_type, :tied_status,
      :hierarchy_id, :fund_id)
  end

  def id
    params[:id]
  end
end
