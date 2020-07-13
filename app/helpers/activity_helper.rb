module ActivityHelper
  def step_is_complete_or_next?(activity:, step:)
    steps = Staff::ActivityFormsController::FORM_STEPS

    return false if activity.form_state.nil?
    return true if activity.form_steps_completed?

    presenter_position = steps.index(step.to_sym)
    activity_position = steps.index(activity.form_state.to_sym)

    presenter_position <= activity_position + 1
  end
end
