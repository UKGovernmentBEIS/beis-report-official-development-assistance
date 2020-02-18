module ActivityHelper
  def step_is_complete_or_next?(activity:, step:)
    steps = Staff::ActivityFormsController::FORM_STEPS

    return false if activity.wizard_status.nil?
    return true if activity.wizard_complete?

    presenter_position = steps.index(step.to_sym)
    activity_position = steps.index(activity.wizard_status.to_sym)

    presenter_position <= activity_position + 1
  end

  def activity_back_path(activity)
    return organisation_path(activity.organisation) if activity.fund?
    organisation_activity_path(activity.parent_activity.organisation, activity.parent_activity)
  end
end
