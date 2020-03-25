class TransactionPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    Pundit.policy!(user, record.activity).create?
  end

  def update?
    Pundit.policy!(user, record.activity).update?
  end

  def destroy?
    Pundit.policy!(user, record.activity).destroy?
  end

  class Scope < Scope
    def resolve
      activities = Activity.where(organisation_id: user.organisation)
      scope.where(activity_id: activities)
    end
  end
end
