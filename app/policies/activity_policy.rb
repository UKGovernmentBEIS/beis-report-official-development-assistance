class ActivityPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator? ||
      fund? && user.fund_manager?
  end

  def create?
    user.administrator? ||
      fund? && user.fund_manager?
  end

  def update?
    user.administrator? ||
      fund? && user.fund_manager?
  end

  def destroy?
    user.administrator? ||
      fund? && user.fund_manager?
  end

  private def fund?
    record.hierarchy.is_a?(Fund)
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        funds = Fund.where(organisation_id: user.organisation)
        scope.where(hierarchy: funds)
      end
    end
  end
end
