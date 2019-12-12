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
end
