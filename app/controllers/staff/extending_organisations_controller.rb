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
      set_implementing_organisation
      @activity.save(context: :update_extending_organisation)
      flash[:notice] = t("action.#{@activity.level}.update.success")
      redirect_to organisation_activity_details_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  private

  def set_implementing_organisation
    extending_organisation = Organisation.find(extending_organisation_id)
    implementing_organisation = ImplementingOrganisation.new(name: extending_organisation.name,
                                                             organisation_type: extending_organisation.organisation_type,
                                                             reference: extending_organisation.iati_reference,
                                                             activity_id: activity_id)
    implementing_organisation.save!
  end

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
