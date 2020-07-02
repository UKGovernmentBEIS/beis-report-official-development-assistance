class Staff::ImplementingOrganisationsController < Staff::BaseController
  def new
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    @implementing_organisation = ImplementingOrganisation.new
  end

  def edit
    @activity = Activity.find(params[:activity_id])
    authorize @activity
    @implementing_organisation = ImplementingOrganisation.find(params[:id])
  end

  def create
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    @implementing_organisation = ImplementingOrganisation.new(implementing_organisation_params)

    if @implementing_organisation.valid?
      @implementing_organisation.save
      flash[:notice] = I18n.t("action.implementing_organisation.create.success")
      redirect_to organisation_activity_details_path(@activity.organisation, @activity)
    else
      render :new
    end
  end

  def update
    @activity = Activity.find(params[:activity_id])
    authorize @activity
    @implementing_organisation = ImplementingOrganisation.find(params[:id])

    @implementing_organisation.assign_attributes(implementing_organisation_params)

    if @implementing_organisation.valid?
      @implementing_organisation.save!
      flash[:notice] = I18n.t("action.implementing_organisation.update.success")
      redirect_to organisation_activity_details_path(@activity.organisation, @activity)
    else
      render :edit
    end
  end

  private

  def implementing_organisation_params
    params.require(:implementing_organisation).permit(:name, :organisation_type, :reference, :activity_id)
  end
end
