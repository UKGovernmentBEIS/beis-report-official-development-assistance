class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard
  include DateHelper
  include ActivityHelper

  FORM_STEPS = [
    :blank,
    :level,
    :parent,
    :identifier,
    :purpose,
    :sector_category,
    :sector,
    :programme_status,
    :dates,
    :geography,
    :region,
    :country,
    :flow,
    :aid_type,
  ]

  steps(*FORM_STEPS)

  def show
    @activity = Activity.find(activity_id)
    @page_title = t("page_title.activity_form.show.#{step}", sector_category: t("activity.sector_category.#{@activity.sector_category}"), level: t("page_content.activity.level.#{@activity.level}"))
    authorize @activity

    case step
    when :parent
      skip_step if @activity.fund?
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
    @activity = Activity.find(activity_id)
    authorize @activity

    case step
    when :level
      @activity.assign_attributes(level: level)
      UpdateActivityAsFund.new(activity: @activity).call if @activity.fund?
    when :parent
      case @activity.level.to_sym
      when :programme then UpdateActivityAsProgramme.new(activity: @activity, parent_id: parent_id).call
      when :project then UpdateActivityAsProject.new(activity: @activity, parent_id: parent_id).call
      when :third_party_project then UpdateActivityAsThirdPartyProject.new(activity: @activity, parent_id: parent_id).call
      end
    when :identifier
      @activity.assign_attributes(identifier: identifier)
      add_transparency_identifier
    when :purpose
      @activity.assign_attributes(title: title, description: description)
    when :sector_category
      @activity.assign_attributes(sector_category: sector_category, sector: nil)
    when :sector
      @activity.assign_attributes(sector: sector)
    when :status
      @activity.assign_attributes(status: status)
    when :dates
      @activity.assign_attributes(
        planned_start_date: format_date(planned_start_date),
        planned_end_date: format_date(planned_end_date),
        actual_start_date: format_date(actual_start_date),
        actual_end_date: format_date(actual_end_date),
      )
    when :geography
      @activity.assign_attributes(geography: geography, recipient_region: nil, recipient_country: nil)
    when :region
      @activity.assign_attributes(recipient_region: recipient_region)
    when :country
      inferred_region = country_to_region_mapping.find { |pair| pair["country"] == recipient_country }["region"]
      @activity.assign_attributes(recipient_region: inferred_region, recipient_country: recipient_country)
    when :flow
      @activity.assign_attributes(flow: flow)
    when :aid_type
      @activity.assign_attributes(aid_type: aid_type)
    end

    update_form_state
    record_auditable_activity

    # `render_wizard` calls save on the object passed to it.
    render_wizard @activity, context: :"#{step}_step"
  end

  private

  def activity_id
    params[:activity_id]
  end

  def level
    params.require(:activity).permit(:level).fetch("level", nil)
  end

  def parent_id
    params.require(:activity).permit(:parent).fetch("parent", nil)
  end

  def identifier
    params.require(:activity).permit(:identifier).fetch("identifier", nil)
  end

  def sector_category
    params.require(:activity).permit(:sector_category).fetch("sector_category", nil)
  end

  def sector
    params.require(:activity).permit(:sector).fetch("sector", nil)
  end

  def title
    params.require(:activity).permit(:title).fetch("title", nil)
  end

  def description
    params.require(:activity).permit(:description).fetch("description", nil)
  end

  def programme_status
    params.require(:activity).permit(:programme_status).fetch("programme_status", nil)
  end

  def planned_start_date
    planned_start_date = params.require(:activity).permit(:planned_start_date)
    {day: planned_start_date["planned_start_date(3i)"], month: planned_start_date["planned_start_date(2i)"], year: planned_start_date["planned_start_date(1i)"]}
  end

  def planned_end_date
    planned_end_date = params.require(:activity).permit(:planned_end_date)
    {day: planned_end_date["planned_end_date(3i)"], month: planned_end_date["planned_end_date(2i)"], year: planned_end_date["planned_end_date(1i)"]}
  end

  def actual_start_date
    actual_start_date = params.require(:activity).permit(:actual_start_date)
    {day: actual_start_date["actual_start_date(3i)"], month: actual_start_date["actual_start_date(2i)"], year: actual_start_date["actual_start_date(1i)"]}
  end

  def actual_end_date
    actual_end_date = params.require(:activity).permit(:actual_end_date)
    {day: actual_end_date["actual_end_date(3i)"], month: actual_end_date["actual_end_date(2i)"], year: actual_end_date["actual_end_date(1i)"]}
  end

  def geography
    params.require(:activity).permit(:geography).fetch("geography", nil)
  end

  def recipient_region
    params.require(:activity).permit(:recipient_region).fetch("recipient_region", nil)
  end

  def recipient_country
    params.require(:activity).permit(:recipient_country).fetch("recipient_country", nil)
  end

  def flow
    params.require(:activity).permit(:flow).fetch("flow", nil)
  end

  def aid_type
    params.require(:activity).permit(:aid_type).fetch("aid_type", nil)
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

  def record_auditable_activity
    action = @activity.form_steps_completed? ? "update" : "create"
    @activity.create_activity key: "activity.#{action}.#{step}", owner: current_user
  end

  def country_to_region_mapping
    yaml = YAML.safe_load(File.read("#{Rails.root}/vendor/data/codelists/BEIS/country_to_region_mapping.yml"))
    yaml["data"]
  end

  def add_transparency_identifier
    @activity.update(transparency_identifier: @activity.iati_identifier)
  end
end
