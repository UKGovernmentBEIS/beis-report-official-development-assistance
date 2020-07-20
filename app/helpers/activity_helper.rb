module ActivityHelper
  def step_is_complete_or_next?(activity:, step:)
    steps = Staff::ActivityFormsController::FORM_STEPS

    return false if activity.form_state.nil?
    return true if activity.form_steps_completed?
    return true if activity.fund? && step == :identifier

    presenter_position = steps.index(step.to_sym)
    activity_position = steps.index(activity.form_state.to_sym)

    presenter_position <= activity_position + 1
  end

  def link_to_activity_parent(parent:, user:)
    return if parent.nil?
    return parent.title if parent.fund? && user.delivery_partner?
    link_to parent.title, organisation_activity_path(parent.organisation, parent), {class: "govuk-link govuk-link--no-visited-state"}
  end
end
