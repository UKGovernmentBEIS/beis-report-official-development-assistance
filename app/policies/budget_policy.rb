class BudgetPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator? ||
      user.fund_manager? ||
      activity_is_project_level? && user.delivery_partner?
  end

  def create?
    user.administrator? ||
      user.fund_manager? ||
      activity_is_project_level? && user.delivery_partner?
  end

  def update?
    user.administrator? ||
      user.fund_manager? ||
      activity_is_project_level? && user.delivery_partner?
  end

  def destroy?
    user.administrator? || user.fund_manager?
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
      if user.administrator? || user.fund_manager?
        scope.all
      else
        activities = Activity.where(organisation_id: user.organisation)
        scope.where(activity_id: activities)
      end
    end
  end
end
