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

  def programme_id
    params[:programme_id]
  end

  def hierarchy
    # TODO: This will eventually become unsustainable,
    # we need a better way
    if fund_id
      @hierarchy = authorize Fund.find(fund_id)
    elsif programme_id
      @hierarchy = authorize Programme.find(programme_id)
    end
  end
end
