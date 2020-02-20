class TransactionPolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  class Scope < Scope
    def resolve
      activities = Activity.where(organisation_id: user.organisation)
      scope.where(activity_id: activities)
    end
  end
end
