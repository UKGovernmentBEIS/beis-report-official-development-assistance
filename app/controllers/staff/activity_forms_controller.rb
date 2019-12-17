class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard
  include DateHelper
  include ActivityHelper

  steps(
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
  )

  def index
    skip_policy_scope
    authorize :activity, :index?

    super
  end

  def show
    @page_title = t("page_title.activity_form.show.#{step}")

    @activity = policy_scope(Activity).find(params[:activity_id])
    authorize @activity

    render_wizard
  end

  def update
    @page_title = t("page_title.activity_form.show.#{step}")

    @activity = policy_scope(Activity).find(params[:activity_id])
    authorize @activity

    @activity.assign_attributes(activity_params)
    @activity.wizard_status = step
    @activity.save
    render_wizard @activity
  end

  private

  def activity_params
    params.require(:activity).permit(:identifier, :sector, :title, :description, :status,
      :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date,
      :recipient_region, :flow, :finance, :aid_type, :tied_status)
  end

  def finish_wizard_path
    flash[:notice] = I18n.t("form.activity.create.success")
    hierarchy_path_for(activity: @activity)
  end
end
