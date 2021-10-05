class Staff::CommentsController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed
  include Reports::Breadcrumbed

  def new
    @activity = Activity.find(activity_id)
    @comment = @activity.comments.new(report_id: report_id)
    authorize @comment, policy_class: Activity::CommentPolicy

    prepare_default_report_variance_trail(@comment.report)
    add_breadcrumb t("breadcrumb.comment.new"), new_activity_comment_path(@activity)
  end

  def create
    @activity = Activity.find(activity_id)
    @comment = @activity.comments.create(comment_params)
    authorize @comment, policy_class: Activity::CommentPolicy

    @comment.assign_attributes(owner: current_user)

    if @comment.valid?
      @comment.save!
      flash[:notice] = t("action.comment.create.success")
      redirect_to organisation_activity_comments_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @comment = Comment.find(id)
    @activity = Activity.find(@comment.commentable_id)
    @report = Report.find(@comment.report_id)
    @report_presenter = ReportPresenter.new(@report)
    authorize @comment, policy_class: Activity::CommentPolicy

    prepare_default_activity_trail(@activity, tab: "comments")
    add_breadcrumb t("breadcrumb.comment.edit"), edit_activity_comment_path(@activity, @comment)
  end

  def update
    @comment = Comment.find(id)
    authorize @comment, policy_class: Activity::CommentPolicy

    @comment.assign_attributes(comment_params)
    if @comment.valid?
      @comment.save!
      flash[:notice] = t("action.comment.update.success")
      redirect_to organisation_activity_comments_path(@comment.commentable.organisation, @comment.commentable)
    else
      render :edit
    end
  end

  private

  def id
    params[:id]
  end

  def activity_id
    params[:activity_id]
  end

  def report_id
    params[:report_id]
  end

  def comment_params
    params.require(:comment).permit(:comment, :report_id)
  end
end
