class Staff::ExternalIncomesController < Staff::BaseController
  def new
    @activity = Activity.find(params[:activity_id])
    @external_income = ExternalIncome.new

    authorize @activity
  end

  def create
    @activity = Activity.find(params[:activity_id])
    @external_income = ExternalIncome.new(external_income_params)

    authorize @external_income

    if @external_income.valid?
      @external_income.save
      @external_income.create_activity key: "external_income.create", owner: current_user

      flash[:notice] = t("action.external_income.create.success")
      redirect_to organisation_activity_other_funding_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def edit
    @activity = Activity.find(params[:activity_id])
    @external_income = ExternalIncome.find(params[:id])

    authorize @external_income
  end

  def update
    @activity = Activity.find(params[:activity_id])
    @external_income = ExternalIncome.find(params[:id])

    authorize @external_income

    @external_income.assign_attributes(external_income_params)

    if @external_income.valid?
      @external_income.save
      @external_income.create_activity key: "external_income.update", owner: current_user

      flash[:notice] = t("action.external_income.update.success")
      redirect_to organisation_activity_other_funding_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  def destroy
    @activity = Activity.find(params[:activity_id])
    @external_income = ExternalIncome.find(params[:id])

    authorize @external_income

    @external_income.create_activity key: "external_income.destroy", owner: current_user
    @external_income.destroy

    flash[:notice] = t("action.external_income.destroy.success")
    redirect_to organisation_activity_other_funding_path(@activity.organisation, @activity)
  end

  private

  def external_income_params
    params.require(:external_income).permit(
      :activity_id,
      :organisation_id,
      :amount,
      :financial_quarter,
      :financial_year,
      :oda_funding,
    )
  end
end
