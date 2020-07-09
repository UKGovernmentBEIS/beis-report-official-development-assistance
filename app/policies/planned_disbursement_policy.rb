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
end
