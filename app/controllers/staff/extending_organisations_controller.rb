class Staff::ExtendingOrganisationsController < Staff::BaseController
  def edit
    @activity = Activity.find(activity_id)
    authorize @activity

    @delivery_partners = Organisation.delivery_partners
  end

  def update
    @activity = Activity.find(activity_id)
    authorize @activity

    @activity.assign_attributes(extending_organisation_id: extending_organisation_id)

    if @activity.valid?(:update_extending_organisation)
      @activity.save
      flash[:notice] = I18n.t("form.activity.update.success")
      redirect_to organisation_activity_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  private

  def activity_id
    params[:activity_id]
  end

  def extending_organisation_id
    params[:activity][:extending_organisation_id]
  end

  def activity_params
    params.require(:activity).permit(:extending_organisation_id)
  end
end
