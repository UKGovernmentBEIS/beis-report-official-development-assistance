class Activity
  class GroupedActivitiesFetcher
    def initialize(user:, organisation:, scope: :all)
      @organisation = organisation
      @scope = scope
      @activities = ActivityPolicy::Scope.new(user, Activity).resolve
      @activities = @activities.not_ispf if hide_ispf_for_user?(user)
    end

    def call
      grouped_programmes.each_with_object({}) do |(fund, programmes), funds|
        funds[fund] = programmes.each_with_object({}) { |programme, programmes|
          programmes[programme] = scoped_child_activities_for(programme).each_with_object({}) { |project, projects|
            projects[project] = scoped_child_activities_for(project)
          }
        }
      end
    end

    private

    def grouped_programmes
      programmes = activities.includes(
        :organisation,
        parent: [:parent, :organisation],
        child_activities: [:child_activities, :organisation, :parent]
      ).programme.send(scope)

      unless organisation.service_owner?
        programmes = programmes.where(extending_organisation: organisation)
      end

      programmes.order(:roda_identifier).group_by(&:parent)
    end

    def scoped_child_activities_for(activity)
      activity.child_activities.send(scope).order(:created_at).to_a
    end

    attr_reader :organisation, :activities, :scope
  end
end
