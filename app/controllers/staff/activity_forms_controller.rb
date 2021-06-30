class Staff::ActivityFormsController < Staff::BaseController
  include Wicked::Wizard
  include CodelistHelper

  steps(*Activity::FORM_STEPS)

  def show
    @activity = Activity.find(activity_id)
    @page_title = t("page_title.activity_form.show.#{step}", sector_category: t("activity.sector_category.#{@activity.sector_category}"), level: t("page_content.activity.level.#{@activity.level}"))
    authorize @activity

    case step
    when :roda_identifier
      skip_step unless @activity.can_set_roda_identifier?
    when :objectives
      skip_step if @activity.fund?
    when :programme_status
      skip_step if @activity.fund?
    when :country_delivery_partners
      skip_step unless @activity.is_newton_funded?
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
      skip_step unless Activity::Inference.service.editable?(@activity, :collaboration_type)
      assign_default_collaboration_type_value_if_nil
    when :policy_markers
      skip_step unless @activity.is_project?
    when :sustainable_development_goals
      skip_step if @activity.fund?
    when :gcrf_challenge_area, :gcrf_strategic_area
      skip_step unless @activity.is_gcrf_funded?
    when :fund_pillar
      skip_step unless @activity.is_newton_funded?
    when :channel_of_delivery_code
      skip_step unless @activity.is_project?
      skip_step unless Activity::Inference.service.editable?(@activity, :channel_of_delivery_code)
    when :oda_eligibility_lead
      skip_step unless @activity.is_project?
    when :uk_dp_named_contact
      skip_step unless @activity.is_project?
    when :fstc_applies
      skip_step unless Activity::Inference.service.editable?(@activity, :fstc_applies)
    when :identifier
      skip_step if @activity.delivery_partner_identifier.present?
    end

    render_wizard
  end

  def update
    @activity = Activity.find(activity_id)
    @page_title = t("page_title.activity_form.show.#{step}", sector_category: t("activity.sector_category.#{@activity.sector_category}"), level: t("page_content.activity.level.#{@activity.level}"))
    authorize @activity

    updater = Activity::Updater.new(activity: @activity, params: params)
    updater.update(step)

    if step == :dates && @activity.errors.present?
      render_step :dates
      return
    end

    update_form_state
    record_history
    record_auditable_activity

    # `render_wizard` calls save on the object passed to it.
    render_wizard @activity, context: :"#{step}_step"
  end

  private

  def activity_id
    params[:activity_id]
  end

  def finish_wizard_path
    flash[:notice] ||= t("action.#{@activity.level}.create.success")
    @activity.update(form_state: "complete")
    organisation_activity_details_path(@activity.organisation, @activity)
  end

  def update_form_state
    return if @activity.invalid?("#{step}_step".to_sym)

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

  def record_history
    HistoryRecorder
      .new(user: current_user)
      .call(
        changes: @activity.changes,
        reference: "Update to Activity #{step}",
        activity: @activity,
        report: Report.editable_for_activity(@activity)
      )
  end

  def record_auditable_activity
    action = @activity.form_steps_completed? ? "update" : "create"
    @activity.create_activity key: "activity.#{action}.#{step}", owner: current_user
  end

  def assign_default_collaboration_type_value_if_nil
    # This allows us to pre-select a specific radio button on collaboration_type form step (value "Bilateral" in this case)
    @activity.collaboration_type = "1" if @activity.collaboration_type.nil?
  end
end
