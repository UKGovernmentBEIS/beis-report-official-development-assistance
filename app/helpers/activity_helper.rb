module ActivityHelper
  def hierarchy_path_for(activity:)
    url_for([activity.hierarchy.organisation, activity.hierarchy])
  end

  def activity_path_for(activity:)
    url_for([activity.hierarchy, activity])
  end

  def edit_activity_path_for(activity:, step: :identifier)
    url_for([activity.hierarchy, activity]) + "/steps/#{step}"
  end

  def show_activity_field?(activity:, step:)
    steps = Staff::ActivityFormsController::FORM_STEPS
    form_position = steps.index(step.to_sym)
    activity_position = steps.index(activity.wizard_status.to_sym)

    form_position <= activity_position + 1
  end
end
