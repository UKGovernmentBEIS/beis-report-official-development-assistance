# frozen_string_literal: true

class Staff::ActualsController < Staff::BaseController
  include Secured
  include Activities::Breadcrumbed

  def new
    @activity = activity
    @actual = Actual.new
    @actual.parent_activity = @activity

    @report = Report.editable_for_activity(@activity)
    @actual.financial_quarter = @report&.financial_quarter
    @actual.financial_year = @report&.financial_year

    authorize(@actual)

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.actual.new"), new_activity_actual_path(@activity)
  end

  def create
    @activity = activity
    authorize @activity

    result = CreateActual.new(activity: @activity)
      .call(attributes: actual_params)
    @actual = result.object

    if result.success?
      flash[:notice] = t("action.actual.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @actual = Actual.find(id)
    authorize @actual

    @activity = Activity.find(activity_id)

    prepare_default_activity_trail(@activity)
    add_breadcrumb t("breadcrumb.actual.edit"), edit_activity_actual_path(@activity, @actual)
  end

  def update
    @actual = Actual.find(id)
    authorize @actual
    @activity = activity
    result = UpdateActual.new(
      actual: @actual,
      user: current_user,
      report: Report.editable_for_activity(@activity)
    ).call(attributes: actual_params)

    if result.success?
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
    params.require(:actual).permit(
      :value,
      :financial_quarter,
      :financial_year,
      :receiving_organisation_name,
      :receiving_organisation_reference,
      :receiving_organisation_type
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
