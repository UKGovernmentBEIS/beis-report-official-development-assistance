class Export::ActivityDeliveryPartnerOrganisationColumn
  def initialize(activities_relation:)
    @activities_relation = valid_activities_relation(activities_relation)
  end

  def headers
    ["Delivery partner organisation"]
  end

  def rows
    @activities_relation.includes(:implementing_organisations, :organisation).map { |activity|
      if activity.level == "programme"
        implementing_organisation_names =
          activity.implementing_organisations.map { |org| organisations.fetch(org.id, nil) }
        [activity.id, [implementing_organisation_names.join("|")]]
      else
        [activity.id, [organisations.fetch(activity.organisation_id, nil)]]
      end
    }.to_h
  end

  private

  def valid_activities_relation(activities_relation)
    raise ArgumentError.new("activities must be an ActiveRecord:Relation") unless activities_relation.is_a?(ActiveRecord::Relation)
    activities_relation
  end

  def organisations_for_activities
    @organisations ||=
      Organisation.where(id: @activities_relation.pluck(:organisation_id)).pluck(:id, :name)
  end

  def implementing_organisations_for_activities
    @implementing_organisations ||= Organisation.implementing.pluck(:id, :name)
  end

  def organisations
    (organisations_for_activities + implementing_organisations_for_activities).to_h
  end
end
