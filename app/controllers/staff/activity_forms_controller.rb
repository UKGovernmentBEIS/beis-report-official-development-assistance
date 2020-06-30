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
    @activity = Activity.find(params[:activity_id])
    @page_title = t("page_title.activity_form.show.#{step}", sector_category: t("activity.sector_category.#{@activity.sector_category}"), level: t("page_content.activity.level.#{@activity.level}"))
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

    if @activity.form_steps_completed?
      reset_geography_dependent_answers if step == :geography
      @activity.update(sector: nil) if step == :sector_category
    end

    update_form_state

    render_wizard @activity, context: :"#{step}_step"
  end

  private

  def record_auditable_activity
    action = @activity.form_steps_completed? ? "update" : "create"
    @activity.create_activity key: "activity.#{action}.#{step}", owner: current_user
  end

  def date_field_params_regex
    # This regex will match the three date params from `date_field`;
    # e.g. actual_start_date(2i) actual_start_date(1i) actual_start_date(3i)
    /^(planned|actual)_(start|end)_date\([1-3]i\)$/
  end

  def update_activity_attributes_except_dates
    activity_params_except_dates = activity_params.reject { |param| param.match(date_field_params_regex) }
    update_activity_recipient_region
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
    flash[:notice] ||= I18n.t("action.#{@activity.level}.create.success")
    @activity.update(form_state: "complete")
    organisation_activity_details_path(@activity.organisation, @activity)
  end

  def update_form_state
    return if @activity.invalid?

    if @activity.form_steps_completed?
      flash[:notice] ||= I18n.t("action.#{@activity.level}.update.success")
      jump_to Wicked::FINISH_STEP
    else
      @activity.form_state = step
    end
  end

  def reset_geography_dependent_answers
    @activity.update(recipient_region: nil, recipient_country: nil)
  end

  def update_activity_recipient_region
    return unless activity_params[:recipient_country].present?

    country = activity_params[:recipient_country]
    region = country_to_region_mapping.find { |pair| pair["country"] == country }["region"]

    @activity.update(recipient_region: region)
  end

  def country_to_region_mapping
    yaml = YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/BEIS/country_to_region_mapping.yml"))
    yaml["data"]
  end
end
