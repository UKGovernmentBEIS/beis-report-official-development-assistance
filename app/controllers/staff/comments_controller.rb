class Staff::CommentsController < Staff::BaseController
  include Secured

  def new
    @activity = Activity.find(activity_id)
    @report = Report.find(report_id)
    @comment = Comment.new(activity_id: activity_id, report_id: report_id)
    authorize @comment
    @report_presenter = ReportPresenter.new(@report)
  end

  def create
    @comment = Comment.create(comment_params)
    authorize @comment
    @comment.assign_attributes(owner: current_user)

    if @comment.valid?
      @comment.save!
      flash[:notice] = t("action.comment.create.success")
      redirect_to organisation_activity_comments_path(@comment.activity.organisation, @comment.activity)
    else
      render :new
    end
  end

  def edit
    @comment = Comment.find(id)
    @activity = Activity.find(@comment.activity_id)
    @report = Report.find(@comment.report_id)
    @report_presenter = ReportPresenter.new(@report)
    authorize @comment
  end

  def update
    @comment = Comment.find(id)
    authorize @comment

    @comment.assign_attributes(comment_params)
    if @comment.valid?
      @comment.save!
      flash[:notice] = t("action.comment.update.success")
      redirect_to organisation_activity_comments_path(@comment.activity.organisation, @comment.activity)
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
    params.require(:comment).permit(:comment, :activity_id, :report_id)
  end
end
