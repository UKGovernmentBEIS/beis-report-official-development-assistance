# frozen_string_literal: true

class Staff::PlannedDisbursementsController < Staff::BaseController
  def new
    @activity = Activity.find(params["activity_id"])
    @planned_disbursement = PlannedDisbursement.new
    @planned_disbursement.parent_activity = @activity
    pre_fill_financial_quarter_and_year

    authorize @planned_disbursement
  end

  def create
    @activity = Activity.find(params["activity_id"])
    authorize @activity

    history = history_for_create

    begin
      history.set_value(planned_disbursement_params[:value])
    rescue PlannedDisbursementHistory::SequenceError
      @planned_disbursement = PlannedDisbursement.new(planned_disbursement_params)
      @planned_disbursement.parent_activity = @activity
      @planned_disbursement.errors.add(:financial_quarter, :in_the_past)
      render :new
      return
    rescue ConvertFinancialValue::Error
      @planned_disbursement = PlannedDisbursement.new(planned_disbursement_params)
      @planned_disbursement.parent_activity = @activity
      @planned_disbursement.errors.add(:value, :not_a_number)
      render :new
      return
    end

    flash[:notice] = t("action.planned_disbursement.create.success")
    redirect_to organisation_activity_path(@activity.organisation, @activity)
  end

  def edit
    @activity = Activity.find(params["activity_id"])
    history = history_for_update
    @planned_disbursement = PlannedDisbursementPresenter.new(history.latest_entry)
    authorize @planned_disbursement
  end

  def update
    @activity = Activity.find(params["activity_id"])
    history = history_for_update
    @planned_disbursement = history.latest_entry
    authorize @planned_disbursement

    begin
      history.set_value(planned_disbursement_params[:value])
    rescue ConvertFinancialValue::Error
      @planned_disbursement = PlannedDisbursementPresenter.new(history.latest_entry)
      @planned_disbursement.value = planned_disbursement_params[:value]
      @planned_disbursement.errors.add(:value, :not_a_number)
      render :edit
      return
    end

    flash[:notice] = t("action.planned_disbursement.update.success")
    redirect_to organisation_activity_path(@activity.organisation, @activity)
  end

  private def history_for_create
    PlannedDisbursementHistory.new(
      @activity,
      planned_disbursement_params[:financial_quarter],
      planned_disbursement_params[:financial_year],
      user: current_user
    )
  end

  private def history_for_update
    PlannedDisbursementHistory.new(@activity, params[:quarter], params[:year], user: current_user)
  end

  private def planned_disbursement_params
    params.require(:planned_disbursement).permit(
      :currency,
      :value,
      :financial_quarter,
      :financial_year,
    )
  end

  private def pre_fill_financial_quarter_and_year
    @planned_disbursement.financial_quarter = FinancialPeriod.current_quarter_string
    @planned_disbursement.financial_year = FinancialPeriod.current_year_string
  end
end
