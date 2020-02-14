class ActivityPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user_can_access?
  end

  def create?
    user_can_create_and_update?
  end

  def update?
    user_can_create_and_update?
  end

  def destroy?
    user.administrator? || user.fund_manager?
  end

  private def associated_delivery_partner?
    user.delivery_partner? && user.organisation.id.eql?(record.organisation_id)
  end

  private def user_can_access?
    return true if user.administrator? || user.fund_manager?
    associated_delivery_partner?
  end

  private def user_can_create_and_update?

    return true if user.administrator?
    return true if user.fund_manager? && !record.level.eql?("project")
    associated_delivery_partner? && record.level.eql?("project")
  end

  class Scope < Scope
    def resolve
      if user.administrator? || user.fund_manager?
        scope.all
      else
        scope.where(organisation: user.organisation)
      end
    end
  end
end
