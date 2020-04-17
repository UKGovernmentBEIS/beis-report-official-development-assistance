class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard
  include DateHelper
  include ActivityHelper

  FORM_STEPS = [
    :blank,
    :identifier,
    :purpose,
    :sector_category,
    :sector,
    :status,
    :dates,
    :geography,
    :region,
    :country,
    :flow,
    :aid_type,
  ]

  steps(*FORM_STEPS)

  def show
    @page_title = t("page_title.activity_form.show.#{step}")
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    case step
    when :blank
      skip_step
    when :region
      skip_step if @activity.recipient_country?
    when :country
      skip_step if @activity.recipient_region?
    end

    render_wizard
  end

  def update
    @page_title = t("page_title.activity_form.show.#{step}")
    @activity = Activity.find(params[:activity_id])
    authorize @activity

    update_activity_dates
    update_activity_attributes_except_dates
    record_auditable_activity

    update_wizard_status

    render_wizard @activity
  end

  private

  def record_auditable_activity
    action = @activity.wizard_complete? ? "update" : "create"
    @activity.create_activity key: "activity.#{action}.#{step}", owner: current_user
  end

  def date_field_params_regex
    # This regex will match the three date params from `date_field`;
    # e.g. actual_start_date(2i) actual_start_date(1i) actual_start_date(3i)
    /^(planned|actual)_(start|end)_date\([1-3]i\)$/
  end

  def update_activity_attributes_except_dates
    activity_params_except_dates = activity_params.reject { |param| param.match(date_field_params_regex) }
    @activity.assign_attributes(activity_params_except_dates)
  end

  def update_activity_dates
    activity_date_params = activity_params.select { |param| param.match(date_field_params_regex) }
    return if activity_date_params.empty?
    @activity.update(planned_start_date: format_date(date_params("planned_start_date")))
    @activity.update(planned_end_date: format_date(date_params("planned_end_date")))
    @activity.update(actual_start_date: format_date(date_params("actual_start_date")))
    @activity.update(actual_end_date: format_date(date_params("actual_end_date")))
  end

  def date_params(date_type_string)
    {day: activity_params["#{date_type_string}(3i)"], month: activity_params["#{date_type_string}(2i)"], year: activity_params["#{date_type_string}(1i)"]}
  end

  def activity_params
    params.require(:activity).permit(:identifier, :sector_category, :sector, :title, :description, :status,
      :planned_start_date, :planned_end_date, :actual_start_date, :actual_end_date,
      :geography, :recipient_region, :recipient_country, :flow,
      :aid_type)
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
