module ActivityHelper
  def activity_path_for(fund:)
    fund_path(fund)
  end

  def step_is_complete_or_next?(activity:, step:)
    steps = Staff::ActivityFormsController::FORM_STEPS

    return true if activity.wizard_status.nil?

    presenter_position = steps.index(step.to_sym)
    activity_position = steps.index(activity.wizard_status.to_sym)

    presenter_position <= activity_position + 1
  end
end
