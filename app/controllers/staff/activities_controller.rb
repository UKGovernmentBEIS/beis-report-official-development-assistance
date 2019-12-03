# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
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

  def create
    @activity = policy_scope(Activity).new
    authorize @activity

    @fund = policy_scope(Fund).find(params[:fund_id])
    @activity.hierarchy = @fund

    @activity.save(validate: false)

    redirect_to fund_activity_steps_path(@fund, @activity)
  end

  private

  def id
    params[:id]
  end
end
