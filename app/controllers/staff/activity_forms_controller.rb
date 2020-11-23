class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard
  include DateHelper
  include ActivityHelper

  DEFAULT_PROGRAMME_STATUS_FOR_FUNDS = "07"

  FORM_STEPS = [
    :blank,
    :level,
    :parent,
    :identifier,
    :roda_identifier,
    :purpose,
    :objectives,
    :sector_category,
    :sector,
    :call_present,
    :call_dates,
    :total_applications_and_awards,
    :programme_status,
    :dates,
    :geography,
    :region,
    :country,
    :requires_additional_benefitting_countries,
    :intended_beneficiaries,
    :gdi,
    :collaboration_type,
    :flow,
    :sustainable_development_goals,
    :aid_type,
    :fstc_applies,
    :policy_markers,
    :covid19_related,
    :oda_eligibility,
    :oda_eligibility_lead,
  ]

  steps(*FORM_STEPS)

  def show
    @activity = Activity.find(activity_id)
    @page_title = t("page_title.activity_form.show.#{step}", sector_category: t("activity.sector_category.#{@activity.sector_category}"), level: t("page_content.activity.level.#{@activity.level}"))
    authorize @activity

    case step
    when :parent
      skip_step if @activity.fund?
    when :roda_identifier
      skip_step unless @activity.can_set_roda_identifier?
    when :blank
      skip_step
    when :objectives
      skip_step if @activity.fund?
    when :programme_status
      skip_step if @activity.fund?
    when :call_present
      skip_step unless @activity.requires_call_dates?
    when :call_dates
      skip_step unless @activity.call_present?
    when :total_applications_and_awards
      skip_step unless @activity.call_present?
    when :region
      skip_step if @activity.recipient_country?
    when :country
      skip_step if @activity.recipient_region?
    when :intended_beneficiaries
      skip_step unless @activity.requires_additional_benefitting_countries?
    when :collaboration_type
      skip_step if @activity.fund?
      assign_default_collaboration_type_value_if_nil
    when :policy_markers
      skip_step unless @activity.is_project?
    when :sustainable_development_goals
      skip_step if @activity.fund?
    when :oda_eligibility_lead
      skip_step unless @activity.is_project?
    end

    render_wizard
  end

  def update
    @activity = Activity.find(activity_id)
    @page_title = t("page_title.activity_form.show.#{step}", sector_category: t("activity.sector_category.#{@activity.sector_category}"), level: t("page_content.activity.level.#{@activity.level}"))
    authorize @activity

    if @activity.fund?
      iati_status = ProgrammeToIatiStatus.new.programme_status_to_iati_status(DEFAULT_PROGRAMME_STATUS_FOR_FUNDS)
      @activity.assign_attributes(programme_status: DEFAULT_PROGRAMME_STATUS_FOR_FUNDS, status: iati_status)
    end

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
      @activity.assign_attributes(delivery_partner_identifier: delivery_partner_identifier)
    when :roda_identifier
      @activity.assign_attributes(roda_identifier_fragment: roda_identifier_fragment)
      @activity.cache_roda_identifier!
    when :purpose
      @activity.assign_attributes(title: title, description: description)
    when :objectives
      @activity.assign_attributes(objectives: objectives)
    when :sector_category
      @activity.assign_attributes(sector_category: sector_category, sector: nil)
    when :sector
      @activity.assign_attributes(sector: sector)
    when :call_present
      @activity.assign_attributes(call_present: call_present)
    when :call_dates
      @activity.assign_attributes(
        call_open_date: format_date(call_open_date),
        call_close_date: format_date(call_close_date),
      )
    when :total_applications_and_awards
      @activity.assign_attributes(total_applications: total_applications, total_awards: total_awards)
    when :programme_status
      iati_status = ProgrammeToIatiStatus.new.programme_status_to_iati_status(programme_status)
      @activity.assign_attributes(programme_status: programme_status, status: iati_status)
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
      if recipient_country.blank?
        @activity.assign_attributes(recipient_country: nil)
      else
        inferred_region = country_to_region_mapping.find { |pair| pair["country"] == recipient_country }["region"]
        @activity.assign_attributes(recipient_region: inferred_region, recipient_country: recipient_country)
      end
    when :requires_additional_benefitting_countries
      @activity.assign_attributes(requires_additional_benefitting_countries: requires_additional_benefitting_countries)
    when :intended_beneficiaries
      @activity.assign_attributes(intended_beneficiaries: intended_beneficiaries.drop(1))
    when :gdi
      @activity.assign_attributes(gdi: gdi)
    when :collaboration_type
      @activity.assign_attributes(collaboration_type: collaboration_type)
    when :flow
      @activity.assign_attributes(flow: flow)
    when :aid_type
      @activity.assign_attributes(aid_type: aid_type)
    when :fstc_applies
      @activity.assign_attributes(fstc_applies: fstc_applies)
    when :policy_markers
      @activity.assign_attributes(
        policy_marker_gender: policy_markers_iati_codes_to_enum(policy_marker_gender),
        policy_marker_climate_change_adaptation: policy_markers_iati_codes_to_enum(policy_marker_climate_change_adaptation),
        policy_marker_climate_change_mitigation: policy_markers_iati_codes_to_enum(policy_marker_climate_change_mitigation),
        policy_marker_biodiversity: policy_markers_iati_codes_to_enum(policy_marker_biodiversity),
        policy_marker_desertification: policy_markers_iati_codes_to_enum(policy_marker_desertification),
        policy_marker_disability: policy_markers_iati_codes_to_enum(policy_marker_disability),
        policy_marker_disaster_risk_reduction: policy_markers_iati_codes_to_enum(policy_marker_disaster_risk_reduction),
        policy_marker_nutrition: policy_markers_iati_codes_to_enum(policy_marker_nutrition),
      )
    when :covid19_related
      @activity.assign_attributes(covid19_related: covid19_related)
    when :sustainable_development_goals
      @activity.assign_attributes(sustainable_development_goals)

      unless @activity.sdgs_apply?
        @activity.assign_attributes(sdg_1: nil, sdg_2: nil, sdg_3: nil)
      end
    when :oda_eligibility
      @activity.assign_attributes(oda_eligibility: oda_eligibility)
    when :oda_eligibility_lead
      @activity.assign_attributes(oda_eligibility_lead: oda_eligibility_lead)
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

  def delivery_partner_identifier
    params.require(:activity).permit(:delivery_partner_identifier).fetch("delivery_partner_identifier", nil)
  end

  def roda_identifier_fragment
    params.require(:activity).permit(:roda_identifier_fragment).fetch("roda_identifier_fragment", nil)
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

  def objectives
    params.require(:activity).permit(:objectives).fetch("objectives", nil)
  end

  def call_present
    params.require(:activity).permit(:call_present).fetch("call_present", nil)
  end

  def call_open_date
    call_open_date = params.require(:activity).permit(:call_open_date)
    {day: call_open_date["call_open_date(3i)"], month: call_open_date["call_open_date(2i)"], year: call_open_date["call_open_date(1i)"]}
  end

  def call_close_date
    call_close_date = params.require(:activity).permit(:call_close_date)
    {day: call_close_date["call_close_date(3i)"], month: call_close_date["call_close_date(2i)"], year: call_close_date["call_close_date(1i)"]}
  end

  def total_applications
    params.require(:activity).permit(:total_applications).fetch("total_applications", nil)
  end

  def total_awards
    params.require(:activity).permit(:total_awards).fetch("total_awards", nil)
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

  def requires_additional_benefitting_countries
    params.require(:activity).permit(:requires_additional_benefitting_countries).fetch("requires_additional_benefitting_countries", nil)
  end

  def intended_beneficiaries
    params.require(:activity).permit(intended_beneficiaries: []).fetch("intended_beneficiaries", [])
  end

  def gdi
    params.require(:activity).permit(:gdi).fetch("gdi", nil)
  end

  def collaboration_type
    params.require(:activity).permit(:collaboration_type).fetch("collaboration_type", nil)
  end

  def flow
    params.require(:activity).permit(:flow).fetch("flow", nil)
  end

  def sustainable_development_goals
    params.require(:activity).permit(:sdg_1, :sdg_2, :sdg_3, :sdgs_apply)
  end

  def aid_type
    params.require(:activity).permit(:aid_type).fetch("aid_type", nil)
  end

  def fstc_applies
    params.require(:activity).permit(:fstc_applies).fetch("fstc_applies", nil)
  end

  def policy_marker_gender
    params.require(:activity).permit(:policy_marker_gender).fetch("policy_marker_gender", nil)
  end

  def policy_marker_climate_change_adaptation
    params.require(:activity).permit(:policy_marker_climate_change_adaptation).fetch("policy_marker_climate_change_adaptation", nil)
  end

  def policy_marker_climate_change_mitigation
    params.require(:activity).permit(:policy_marker_climate_change_mitigation).fetch("policy_marker_climate_change_mitigation", nil)
  end

  def policy_marker_biodiversity
    params.require(:activity).permit(:policy_marker_biodiversity).fetch("policy_marker_biodiversity", nil)
  end

  def policy_marker_desertification
    params.require(:activity).permit(:policy_marker_desertification).fetch("policy_marker_desertification", nil)
  end

  def policy_marker_disability
    params.require(:activity).permit(:policy_marker_disability).fetch("policy_marker_disability", nil)
  end

  def policy_marker_disaster_risk_reduction
    params.require(:activity).permit(:policy_marker_disaster_risk_reduction).fetch("policy_marker_disaster_risk_reduction", nil)
  end

  def policy_marker_nutrition
    params.require(:activity).permit(:policy_marker_nutrition).fetch("policy_marker_nutrition", nil)
  end

  def covid19_related
    params.require(:activity).permit(:covid19_related).fetch("covid19_related", 0)
  end

  def oda_eligibility
    params.require(:activity).permit(:oda_eligibility).fetch("oda_eligibility", nil)
  end

  def oda_eligibility_lead
    params.require(:activity).permit(:oda_eligibility_lead).fetch("oda_eligibility_lead", nil)
  end

  def finish_wizard_path
    flash[:notice] ||= t("action.#{@activity.level}.create.success")
    @activity.update(form_state: "complete")
    organisation_activity_details_path(@activity.organisation, @activity)
  end

  def update_form_state
    return if @activity.invalid?(step)

    if step == :geography && @activity.geography == "recipient_country"
      jump_to :country
    elsif step == :geography && @activity.geography == "recipient_region"
      jump_to :region
    elsif step == :sector_category
      jump_to :sector
    elsif @activity.form_steps_completed?
      flash[:notice] ||= t("action.#{@activity.level}.update.success")
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

  def assign_default_collaboration_type_value_if_nil
    # This allows us to pre-select a specific radio button on collaboration_type form step (value "Bilateral" in this case)
    @activity.collaboration_type = "1" if @activity.collaboration_type.nil?
  end

  def policy_markers_iati_codes_to_enum(code)
    case code
    when "0" then "not_targeted"
    when "1" then "significant_objective"
    when "2" then "principal_objective"
    when "3" then "principal_objective_and_in_support"
    when "1000" then "not_assessed"
    end
  end
end
