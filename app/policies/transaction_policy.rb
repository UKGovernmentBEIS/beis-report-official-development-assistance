class TransactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator? ||
      activity? && user.fund_manager?
  end

  def create?
    user.administrator? ||
      activity? && user.fund_manager?
  end

  def update?
    user.administrator? ||
      activity? && user.fund_manager?
  end

  def destroy?
    user.administrator? ||
      activity? && user.fund_manager?
  end

  private def activity?
    record.activity_id.present?
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        organisations = user.organisation_ids
        activities = Activity.where(organisation_id: organisations)
        scope.where(activity_id: activities)
      end
    end
  end
end
