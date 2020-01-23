class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard
  include DateHelper
  include ActivityHelper

  FORM_STEPS = [
    :identifier,
    :purpose,
    :sector,
    :status,
    :dates,
    :country,
    :flow,
    :finance,
    :aid_type,
    :tied_status,
  ]

  steps(*FORM_STEPS)

  def show
    @page_title = t("page_title.activity_form.show.#{step}")
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    render_wizard
  end

  def update
    @page_title = t("page_title.activity_form.show.#{step}")
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    @activity.assign_attributes(activity_params)
    update_wizard_status

    render_wizard @activity
  end

  private

  def activity_params
    params.require(:activity).permit(:identifier, :sector, :title, :description, :status,
      :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date,
      :recipient_region, :flow, :finance, :aid_type, :tied_status)
  end

  def finish_wizard_path
    flash[:notice] ||= I18n.t("form.#{@activity.level}.create.success")
    @activity.update(wizard_status: "complete")
    organisation_activity_path(@activity.organisation, @activity)
  end

  def update_wizard_status
    return if @activity.invalid?

    if @activity.wizard_complete?
      flash[:notice] ||= I18n.t("form.#{@activity.level}.update.success")
      jump_to Wicked::FINISH_STEP
    else
      @activity.wizard_status = step
    end
  end
end
