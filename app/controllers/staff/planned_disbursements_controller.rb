# frozen_string_literal: true

class Staff::PlannedDisbursementsController < Staff::BaseController
  def new
    @activity = Activity.find(params["activity_id"])
    @planned_disbursement = PlannedDisbursement.new
    @planned_disbursement.parent_activity = @activity
    pre_fill_providing_organisation

    authorize @planned_disbursement
  end

  def create
    @activity = Activity.find(params["activity_id"])
    authorize @activity

    result = CreatePlannedDisbursement.new(activity: @activity).call(attributes: planned_disbursement_params)
    @planned_disbursement = result.object

    if result.success?
      flash[:notice] = I18n.t("form.planned_disbursement.create.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @planned_disbursement = PlannedDisbursement.find(params["id"])
    authorize @planned_disbursement

    @activity = @planned_disbursement.parent_activity
  end

  def update
    @planned_disbursement = PlannedDisbursement.find(params["id"])
    authorize @planned_disbursement

    @activity = Activity.find(params["activity_id"])
    result = UpdatePlannedDisbursement.new(planned_disbursement: @planned_disbursement)
      .call(attributes: planned_disbursement_params)

    if result.success?
      flash[:notice] = I18n.t("form.planned_disbursement.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  private

  def planned_disbursement_params
    params.require(:planned_disbursement).permit(
      :planned_disbursement_type,
      :period_start_date,
      :period_end_date,
      :currency,
      :value,
      :providing_organisation_name,
      :providing_organisation_type,
      :providing_organisation_reference,
      :receiving_organisation_name,
      :receiving_organisation_type,
      :receiving_organisation_reference
    )
  end

  def pre_fill_providing_organisation
    @planned_disbursement.providing_organisation_name = @activity.providing_organisation.name
    @planned_disbursement.providing_organisation_type = @activity.providing_organisation.organisation_type
    @planned_disbursement.providing_organisation_reference = @activity.providing_organisation.iati_reference
  end
end
