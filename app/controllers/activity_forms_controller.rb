class ActivityFormsController < BaseController
  include Wicked::Wizard
  include CodelistHelper
  include Activities::Breadcrumbed

  steps(*Activity::FORM_STEPS)

  def show
    @activity = Activity.find(activity_id)
    @page_title = page_title(step)

    authorize @activity

    prepare_default_activity_trail(@activity, tab: "details")
    add_breadcrumb @page_title, activity_step_path(@activity.id, step)

    case step
    when :is_oda
      skip_step unless @activity.requires_is_oda?
    when :identifier
      @label_text = @activity.is_project? ? t("form.label.activity.partner_organisation_identifier") : t("form.label.activity.partner_organisation_identifier_level_b")
      skip_step if @activity.partner_organisation_identifier.present?
    when :linked_activity
      skip_step unless @activity.is_ispf_funded? && (@activity.programme? || @activity.project?)
      skip_step unless policy(@activity).update_linked_activity?
      @options = linkable_activities_options(@activity)
    when :objectives
      skip_step unless @activity.requires_objectives?
    when :call_present
      skip_step unless @activity.requires_call_dates?
    when :call_dates
      skip_step unless @activity.call_present?
    when :total_applications_and_awards
      skip_step unless @activity.call_present?
    when :programme_status
      skip_step if @activity.fund?
    when :country_partner_organisations
      skip_step unless @activity.is_newton_funded?
    when :ispf_partner_countries
      skip_step unless @activity.is_ispf_funded?
    when :benefitting_countries
      skip_step unless @activity.requires_benefitting_countries?
    when :gdi
      skip_step unless @activity.requires_gdi?
    when :aid_type
      skip_step unless @activity.requires_aid_type?
    when :collaboration_type
      skip_step unless @activity.requires_collaboration_type?
      skip_step unless Activity::Inference.service.editable?(@activity, :collaboration_type)
      assign_default_collaboration_type_value_if_nil
    when :sustainable_development_goals
      skip_step if @activity.fund? || @activity.is_non_oda?
    when :ispf_theme
      skip_step unless @activity.is_ispf_funded?
    when :fund_pillar
      skip_step unless @activity.is_newton_funded?
    when :fstc_applies
      skip_step unless @activity.requires_fstc_applies?
      skip_step unless Activity::Inference.service.editable?(@activity, :fstc_applies)
    when :policy_markers
      skip_step unless @activity.requires_policy_markers?
    when :covid19_related
      skip_step unless @activity.requires_covid19_related?
    when :gcrf_challenge_area, :gcrf_strategic_area
      skip_step unless @activity.is_gcrf_funded?
    when :channel_of_delivery_code
      skip_step unless @activity.requires_channel_of_delivery_code?
      skip_step unless Activity::Inference.service.editable?(@activity, :channel_of_delivery_code)
    when :oda_eligibility
      skip_step unless @activity.requires_oda_eligibility?
    when :oda_eligibility_lead
      skip_step unless @activity.requires_oda_eligibility_lead?
    when :uk_po_named_contact
      skip_step unless @activity.is_project?
    when :implementing_organisation
      skip_step unless @activity.requires_implementing_organisation?
      @implementing_organisations = Organisation.active.sorted_by_name
    end

    render_wizard
  end

  def update
    @activity = Activity.find(activity_id)
    @page_title = page_title(step)

    authorize @activity

    updater = Activity::Updater.new(activity: @activity, params: params)
    updater.update(step)

    if @activity.errors.present?
      case step
      when :dates
        render_step :dates
      when :implementing_organisation
        @implementing_organisations = Organisation.active.sorted_by_name
        render_step :implementing_organisation
      end

      return
    end

    update_form_state
    record_history

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

    if step == :sector_category
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
        trackable: @activity,
        report: Report.editable_for_activity(@activity)
      )
  end

  def assign_default_collaboration_type_value_if_nil
    # This allows us to pre-select a specific radio button on collaboration_type form step (value "Bilateral" in this case)
    @activity.collaboration_type = "1" if @activity.collaboration_type.nil?
  end

  def page_title(step)
    if step == :linked_activity
      @activity.is_oda ? t("page_title.activity_form.show.linked_non_oda_activity") : t("page_title.activity_form.show.linked_oda_activity")
    else
      t("page_title.activity_form.show.#{step}", sector_category: t("activity.sector_category.#{@activity.sector_category}"), level: t("page_content.activity.level.#{@activity.level}"))
    end
  end

  def linkable_activities_options(activity)
    activity.linkable_activities.map { |linkable_activity| ActivityPresenter.new(linkable_activity) }
      .unshift(OpenStruct.new(linkable_activity_select_label: t("form.label.activity.no_linked_activity"), id: ""))
  end
end
