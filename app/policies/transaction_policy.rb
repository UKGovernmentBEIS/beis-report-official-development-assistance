class TransactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator? ||
      activity?
  end

  def create?
    user.administrator? ||
      activity?
  end

  def update?
    user.administrator? ||
      activity?
  end

  def destroy?
    user.administrator? ||
      activity?
  end

  private def activity?
    record.activity_id.present?
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        activities = Activity.where(organisation_id: user.organisation)
        scope.where(activity_id: activities)
      end
    end
  end
end
