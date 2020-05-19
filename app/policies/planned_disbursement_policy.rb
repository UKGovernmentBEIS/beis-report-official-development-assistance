class PlannedDisbursementPolicy < ApplicationPolicy
  def create?
    return false if record.parent_activity.fund? || record.parent_activity.programme?
    Pundit.policy!(user, record.parent_activity).create?
  end

  def update?
    return false if record.parent_activity.fund? || record.parent_activity.programme?
    Pundit.policy!(user, record.parent_activity).update?
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      if user.organisation.service_owner?
        scope.all
      else
        activities = Activity.where(organisation_id: user.organisation)
        scope.where(parent_activity_id: activities)
      end
    end
  end
end
