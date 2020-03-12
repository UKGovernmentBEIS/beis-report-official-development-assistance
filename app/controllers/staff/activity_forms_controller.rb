class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard
  include ActivityHelper
  include DateHelper

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

    # Update activity dates, after checking they are valid via format_date
    update_activity_dates
    # Update all attributes except dates
    @activity.assign_attributes(activity_params.select { |param| param.match(/^((?!date).)*$/) })

    update_wizard_status
    render_wizard @activity
  end

  private

  def update_activity_dates
    return if activity_params.select { |param| param.match(/(.*)date(.*)/) }.empty?
    @activity.update(planned_start_date: format_date(planned_start_date_params))
    @activity.update(planned_end_date: format_date(planned_end_date_params))
    @activity.update(actual_start_date: format_date(actual_start_date_params))
    @activity.update(actual_end_date: format_date(actual_end_date_params))
  end

  def planned_start_date_params
    {day: activity_params["planned_start_date(3i)"], month: activity_params["planned_start_date(2i)"], year: activity_params["planned_start_date(1i)"]}
  end

  def planned_end_date_params
    {day: activity_params["planned_end_date(3i)"], month: activity_params["planned_end_date(2i)"], year: activity_params["planned_end_date(1i)"]}
  end

  def actual_start_date_params
    {day: activity_params["actual_start_date(3i)"], month: activity_params["actual_start_date(2i)"], year: activity_params["actual_start_date(1i)"]}
  end

  def actual_end_date_params
    {day: activity_params["actual_end_date(3i)"], month: activity_params["actual_end_date(2i)"], year: activity_params["actual_end_date(1i)"]}
  end

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
