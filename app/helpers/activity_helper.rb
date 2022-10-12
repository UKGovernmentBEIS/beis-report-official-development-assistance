module ActivityHelper
  include CodelistHelper

  def step_is_complete_or_next?(activity:, step:)
    steps = Activity::FORM_STEPS

    return false if activity.form_state.nil?
    return true if activity.form_steps_completed?
    return true if activity.fund? && step == :identifier

    presenter_position = steps.index(step.to_sym)
    activity_position = steps.index(activity.form_state.to_sym)

    presenter_position <= activity_position + 1
  end

  def link_to_activity_parent(parent:, user:)
    return if parent.nil?
    return parent.title if parent.fund? && user.partner_organisation?
    link_to parent.title, organisation_activity_path(parent.organisation, parent), {class: "govuk-link govuk-link--no-visited-state"}
  end

  def custom_capitalisation(level)
    "#{level[0].upcase}#{level[1..]}"
  end

  def sdg_options
    I18n.t("form.label.activity.sdg_options")
  end

  def policy_markers_iati_codes_to_enum(code)
    Activity::POLICY_MARKER_CODES.key(code.to_i)
  end

  def policy_markers_desertification_iati_codes_to_enum(code)
    Activity::DESERTIFICATION_POLICY_MARKER_CODES.key(code.to_i)
  end

  def benefitting_countries_with_percentages(benefitting_countries)
    return [] if benefitting_countries.blank?

    benefitting_countries.map do |country|
      OpenStruct.new(
        code: country,
        name: country_name_from_code(country),
        percentage: 100 / benefitting_countries.count.to_f
      )
    end
  end

  def edit_comment_path_for(commentable, comment)
    case commentable.class.name
    when "Activity"
      edit_activity_comment_path(commentable, comment)
    when "Actual"
      edit_activity_actual_path(commentable.parent_activity, commentable)
    end
  end
end
