class Staff::ActivityCommentsController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed

  def show
    @activity = Activity.find(activity_id)
    authorize @activity

    prepare_default_activity_trail(@activity)

    @comments = Comment.where(activity_id: activity_id).includes(:report)
  end

  private def activity_id
    params[:activity_id]
  end
end
