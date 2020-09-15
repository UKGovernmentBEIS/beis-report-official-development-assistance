class Staff::ActivityCommentsController < Staff::BaseController
  include Secured

  def show
    @activity = Activity.find(activity_id)
    authorize @activity

    @comments = Comment.where(activity_id: activity_id).includes(:report)

    render "staff/activities/comments"
  end

  private def activity_id
    params[:activity_id]
  end
end
