class Staff::ActivityCommentsController < Staff::BaseController
  include Secured

  def show
    @activity = Activity.find(activity_id)
    authorize @activity

    @comments = Comment.where(activity_id: activity_id).includes(:report)
  end

  private def activity_id
    params[:activity_id]
  end
end
