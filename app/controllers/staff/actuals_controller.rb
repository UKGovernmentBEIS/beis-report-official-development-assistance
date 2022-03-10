# frozen_string_literal: true

class Staff::ActualsController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed

  def new
    @activity = activity
    @report = Report.editable_for_activity(@activity)

    @actual = ActualForm.new(
      parent_activity: @activity,
      financial_quarter: @report&.financial_quarter,
      financial_year: @report&.financial_year
    )

    authorize(@actual, policy_class: ActualPolicy)

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.actual.new"), new_activity_actual_path(@activity)
  end

  def create
    @activity = activity
    authorize @activity
    @actual = ActualForm.new(actual_params)

    actual_created = @actual.valid? && CreateActual.new(
      activity: @activity,
      user: current_user,
      report: Report.editable_for_activity(@activity)
    ).call(attributes: @actual.attributes).success?

    if actual_created
      flash[:notice] = t("action.actual.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @activity = Activity.find(activity_id)
    @actual = ActualForm.new(attributes_for_editing)

    authorize(@actual, policy_class: ActualPolicy)

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.actual.edit"), edit_activity_actual_path(@activity, @actual.id)
  end

  def update
    @activity = activity
    @actual = ActualForm.new(attributes_for_editing.merge(actual_params))
    authorize(@actual, policy_class: ActualPolicy)

    actual_updated = @actual.valid? && UpdateActual.new(
      actual: Actual.find(id),
      user: current_user,
      report: Report.editable_for_activity(@activity)
    ).call(attributes: actual_params).success?

    if actual_updated
      flash[:notice] = t("action.actual.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  def destroy
    @actual = Actual.find(id)
    authorize @actual

    @actual.destroy

    flash[:notice] = t("action.actual.destroy.success")

    redirect_to organisation_activity_path(activity.organisation, activity)
  end

  private

  def actual_params
    params.require(:actual_form).permit(
      :value,
      :financial_quarter,
      :financial_year,
      :receiving_organisation_name,
      :receiving_organisation_reference,
      :receiving_organisation_type
    )
  end

  def attributes_for_editing
    actual = Actual.find(id)

    HashWithIndifferentAccess
      .new
      .merge(actual.attributes.slice(
        "id",
        "value",
        "financial_year",
        "financial_quarter",
        "receiving_organisation_name",
        "receiving_organisation_type",
        "receiving_organisation_reference"
      ))
      .merge(report: actual.report,
        parent_activity: actual.parent_activity)
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
