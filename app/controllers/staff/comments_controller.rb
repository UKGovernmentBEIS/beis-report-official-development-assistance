class Staff::CommentsController < Staff::BaseController
  include Secured

  def index
    @activity = policy_scope(Activity.where(id: activity_id)).first
    @comments = Comment.where(activity_id: activity_id).includes(:report)
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  private

  def id
    params[:id]
  end

  def activity_id
    params[:activity_id]
  end
end
