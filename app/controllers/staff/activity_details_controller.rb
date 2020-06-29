# frozen_string_literal: true

class Staff::ActivityDetailsController < Staff::BaseController
  include Secured

  def show
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    render "staff/activities/details"
  end
end
