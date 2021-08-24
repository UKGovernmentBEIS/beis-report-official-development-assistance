class Staff::RefundsController < Staff::ActivitiesController
  include Secured
  include Activities::Breadcrumbed

  def new
    @activity = activity
    @refund = Refund.new
    @report = Report.editable_for_activity(@activity)

    @refund.parent_activity = @activity
    @refund.report = @report

    authorize @refund

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.refund.new"), new_activity_refund_path(@activity)
  end

  def create
    @activity = activity
    authorize @activity

    result = CreateRefund.new(activity: @activity)
      .call(attributes: refund_params)
    @refund = result.object

    if result.success?
      flash[:notice] = t("action.refund.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @activity = activity
    @refund = Refund.find(id)

    authorize @refund

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.refund.edit"), edit_activity_refund_path(@activity, @refund)
  end

  def update
    @refund = Refund.find(id)
    authorize @refund

    result = UpdateRefund.new(
      refund: @refund,
    ).call(attributes: refund_params)

    if result.success?
      flash[:notice] = t("action.refund.update.success")
      redirect_to organisation_activity_path(activity.organisation, activity)
    else
      render :edit
    end
  end

  def destroy
    @refund = Refund.find(id)
    authorize @refund

    @refund.destroy

    flash[:notice] = t("action.refund.destroy.success")

    redirect_to organisation_activity_path(activity.organisation, activity)
  end

  private

  def refund_params
    params.require(:refund).permit(
      :value,
      :financial_quarter,
      :financial_year,
      :comment
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
