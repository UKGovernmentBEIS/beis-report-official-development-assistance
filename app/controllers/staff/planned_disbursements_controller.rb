# frozen_string_literal: true

class Staff::PlannedDisbursementsController < Staff::BaseController
  def new
    @activity = Activity.find(params["activity_id"])
    @planned_disbursement = PlannedDisbursement.new
    @planned_disbursement.parent_activity = @activity
    pre_fill_providing_organisation
    pre_fill_financial_quarter_and_year

    authorize @planned_disbursement
  end

  def create
    @activity = Activity.find(params["activity_id"])
    authorize @activity

    result = CreatePlannedDisbursement.new(activity: @activity).call(attributes: planned_disbursement_params)
    @planned_disbursement = result.object

    if result.success?
      @planned_disbursement.create_activity key: "planned_disbursement.create", owner: current_user
      flash[:notice] = t("action.planned_disbursement.create.success")
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
      @planned_disbursement.create_activity key: "planned_disbursement.update", owner: current_user
      flash[:notice] = t("action.planned_disbursement.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  private def planned_disbursement_params
    params.require(:planned_disbursement).permit(
      :currency,
      :value,
      :providing_organisation_name,
      :providing_organisation_type,
      :providing_organisation_reference,
      :receiving_organisation_name,
      :receiving_organisation_type,
      :receiving_organisation_reference,
      :financial_quarter,
      :financial_year,
    )
  end

  private def pre_fill_providing_organisation
    @planned_disbursement.providing_organisation_name = @activity.providing_organisation.name
    @planned_disbursement.providing_organisation_type = @activity.providing_organisation.organisation_type
    @planned_disbursement.providing_organisation_reference = @activity.providing_organisation.iati_reference
  end

  private def pre_fill_financial_quarter_and_year
    @planned_disbursement.financial_quarter = FinancialPeriod.current_quarter_string
    @planned_disbursement.financial_year = FinancialPeriod.current_year_string
  end
end
