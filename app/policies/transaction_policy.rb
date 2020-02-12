class TransactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator? ||
      activity? && user.fund_manager? ||
      activity_is_project_level? && user.delivery_partner?
  end

  def create?
    user.administrator? ||
      activity? && user.fund_manager? ||
      activity_is_project_level? && user.delivery_partner?
  end

  def update?
    user.administrator? ||
      activity? && user.fund_manager? ||
      activity_is_project_level? && user.delivery_partner?
  end

  def destroy?
    user.administrator? ||
      activity? && user.fund_manager?
  end

  private def activity?
    record.activity_id.present?
  end

  private def activity_is_project_level?
    return unless activity?
    activity = Activity.find(record.activity_id)
    activity.project?
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
