module ActivityHelper
  def hierarchy_path_for(activity:)
    # TODO there must be a better way
    # organisation_fund_path when hierarchy is a fund
    # fund_programme_path when hierarchy is a programme
    case activity.hierarchy.class.name
    when "Fund"
      url_for([activity.hierarchy.organisation, activity.hierarchy])
    when "Programme"
      url_for([activity.hierarchy.fund, activity.hierarchy])
    end
  end

  def edit_hierarchy_path_for(activity:)
    # TODO there must be a better way
    case activity.hierarchy.class.name
    when "Fund"
      url_for([:edit, activity.hierarchy.organisation, activity.hierarchy])
    when "Programme"
      url_for([:edit, activity.hierarchy.fund, activity.hierarchy])
    end
  end

  def activity_path_for(activity:)
    url_for([activity.hierarchy, activity])
  end

  def edit_activity_path_for(activity:, step: :identifier)
    url_for([activity.hierarchy, activity]) + "/steps/#{step}"
  end

  def show_activity_field?(activity:, step:)
    steps = Staff::ActivityFormsController::FORM_STEPS

    return true if activity.wizard_status.nil?

    form_position = steps.index(step.to_sym)
    activity_position = steps.index(activity.wizard_status.to_sym)

    form_position <= activity_position + 1
  end
end
