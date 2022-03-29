class Staff::RefundsController < Staff::ActivitiesController
  include Secured
  include Activities::Breadcrumbed

  def new
    @activity = activity
    @refund = RefundForm.new(parent_activity: @activity)

    authorize(@refund, policy_class: RefundPolicy)

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.refund.new"), new_activity_refund_path(@activity)
  end

  def create
    @activity = activity
    authorize @activity
    @refund = RefundForm.new(refund_params)

    refund_created = @refund.valid? && CreateRefund.new(
      activity: @activity,
      user: current_user
    ).call(attributes: @refund.attributes).success?

    if refund_created
      flash[:notice] = t("action.refund.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @activity = activity
    @refund = RefundForm.new(attributes_for_editing)

    authorize(@refund, policy_class: RefundPolicy)

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.refund.edit"), edit_activity_refund_path(@activity, @refund.id)
  end

  def update
    @refund = RefundForm.new(attributes_for_editing.merge(refund_params))
    authorize(@refund, policy_class: RefundPolicy)

    refund_updated = @refund.valid? && UpdateRefund.new(
      refund: Refund.find(id),
      user: current_user
    ).call(attributes: refund_params).success?

    if refund_updated
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
    params.require(:refund_form).permit(
      :value,
      :financial_quarter,
      :financial_year,
      :comment
    )
  end

  def attributes_for_editing
    refund = Refund.find(id)

    HashWithIndifferentAccess
      .new
      .merge(refund.attributes.slice(
        "id",
        "value",
        "financial_year",
        "financial_quarter"
      ))
      .merge(report: refund.report,
        parent_activity: refund.parent_activity,
        comment: refund.comment.body)
      .merge(persisted: true)
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
