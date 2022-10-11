class Export::ActivityImplementingOrganisationColumn
  def initialize(activities_relation:)
    @activities = valid_activities(activities_relation)
  end

  def headers
    ["Implementing organisations"]
  end

  def rows
    return [] if @activities.empty?

    @activities.includes(:extending_organisation, :implementing_organisations).map { |activity|
      implementing_organisation_names = if activity.programme?
        extending_organisation_name_for_activity(activity)
      else
        implementing_organisation_names_for_activity(activity)
      end
      [activity.id, [implementing_organisation_names.join("|")]]
    }.to_h
  end

  private

  def extending_organisation_name_for_activity(activity)
    [activity.extending_organisation.name]
  end

  def implementing_organisation_names_for_activity(activity)
    activity.implementing_organisations.map { |organisation| organisation.name }
  end

  def valid_activities(activities)
    raise ArgumentError.new("activities must be an ActiveRecord:Relation") unless activities.is_a?(ActiveRecord::Relation)
    activities
  end
end
