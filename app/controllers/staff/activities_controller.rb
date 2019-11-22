# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include Secured

  def index
    @activities = Fund.for_user(current_user).collect { |fund| fund.activity }.compact
  end

  def show
    activity = Activity.find(id)
    @activity_presenter = ActivityPresenter.new(activity)
  end

  def new
    @funds = Fund.for_user(current_user)
    @activity = Activity.new
  end

  def create
    @activity = Activity.new(activity_params)
    fund = Fund.find(activity_params[:hierarchy_id])
    @activity.hierarchy = fund

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
      :hierarchy_id)
  end

  def id
    params[:id]
  end
end
