class AdjustmentsController < ActivitiesController
  include Secured

  def new
    @activity = activity
    @adjustment = AdjustmentForm.new
    @adjustment.parent_activity = @activity

    authorize(@adjustment, policy_class: AdjustmentPolicy)
  end

  def create
    @adjustment = AdjustmentForm.new(params[:adjustment_form])
    @activity = activity
    @adjustment.parent_activity = @activity

    authorize(@adjustment, policy_class: AdjustmentPolicy)
    return show_errors unless @adjustment.valid?

    result = create_adjustment
    @adjustment = result.object
    if result.success?
      flash[:notice] = t("action.adjustment.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      @adjustment = form_for_correction
      show_errors
    end
  end

  def show
    @activity = activity
    @adjustment = AdjustmentPresenter.new(@activity.adjustments.find(params[:id]))

    authorize @adjustment
  end

  private

  def show_errors
    render :new
  end

  def form_for_correction
    AdjustmentForm
      .new(params[:adjustment_form]
      .merge(parent_activity: activity))
      .tap { |form| form.errors.merge!(@adjustment.errors) }
  end

  def create_adjustment
    CreateAdjustment
      .new(activity: @activity)
      .call(attributes: adjustment_params.merge(
        user: current_user,
        report: Report.editable_for_activity(activity)
      ))
  end

  def adjustment_params
    params.require(:adjustment_form).permit(
      :value,
      :financial_quarter,
      :financial_year,
      :comment,
      :adjustment_type
    )
  end

  def activity_id
    params[:activity_id]
  end

  def id
    params[:id]
  end

  def activity
    @activity ||= Activity.find(activity_id)
  end
end
