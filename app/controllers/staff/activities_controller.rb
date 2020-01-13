# frozen_string_literal: true

class Staff::ActivitiesController < Staff::BaseController
  include ActivityHelper

  def show
    @activity = Activity.find(id)
    authorize @activity

    @activity_presenter = ActivityPresenter.new(@activity)

    respond_to do |format|
      format.html
      format.xml
    end
  end

  def create
    @activity = Activity.new
    @activity.hierarchy = hierarchy
    authorize @activity

    @activity.wizard_status = "identifier"
    @activity.save(validate: false)

    redirect_to url_for([@activity.hierarchy, @activity, :steps])
  end

  private

  def id
    params[:id]
  end

  def fund_id
    params[:fund_id]
  end

  def hierarchy
    # TODO: Add support for new hierarchies here and/or move to a service
    @hierarchy = authorize Fund.find(fund_id)
  end
end
