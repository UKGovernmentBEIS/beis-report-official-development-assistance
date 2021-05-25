class Staff::MatchedEffortsController < Staff::BaseController
  def new
    @activity = Activity.find(params[:activity_id])
    @matched_effort = MatchedEffort.new

    authorize @activity
  end

  def edit
    @activity = Activity.find(params[:activity_id])
    @matched_effort = MatchedEffort.find(params[:id])

    authorize @matched_effort
  end

  def create
    @activity = Activity.find(params[:activity_id])
    @matched_effort = MatchedEffort.new(matched_effort_params)

    authorize @matched_effort

    if @matched_effort.valid?
      @matched_effort.save
      @matched_effort.create_activity key: "matched_effort.create", owner: current_user

      flash[:notice] = t("action.matched_effort.create.success")
      redirect_to organisation_activity_other_funding_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def update
    @activity = Activity.find(params[:activity_id])
    @matched_effort = MatchedEffort.find(params[:id])

    authorize @matched_effort

    @matched_effort.assign_attributes(matched_effort_params)

    if @matched_effort.valid?
      @matched_effort.save
      @matched_effort.create_activity key: "matched_effort.update", owner: current_user

      flash[:notice] = t("action.matched_effort.update.success")
      redirect_to organisation_activity_other_funding_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  def destroy
    @activity = Activity.find(params[:activity_id])
    @matched_effort = MatchedEffort.find(params[:id])

    authorize @matched_effort

    @matched_effort.create_activity key: "matched_effort.destroy", owner: current_user
    @matched_effort.destroy

    flash[:notice] = t("action.matched_effort.destroy.success")
    redirect_to organisation_activity_other_funding_path(@activity.organisation, @activity)
  end

  private

  def matched_effort_params
    params.require(:matched_effort).permit(
      :activity_id,
      :organisation_id,
      :funding_type,
      :category,
      :committed_amount,
      :currency,
      :exchange_rate,
      :date_of_exchange_rate,
      :notes
    )
  end
end
