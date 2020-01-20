class TransactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator? || (user.fund_manager? && hierarchy?)
  end

  def create?
    user.administrator? || (user.fund_manager? && hierarchy?)
  end

  def update?
    user.administrator? || (user.fund_manager? && hierarchy?)
  end

  def destroy?
    user.administrator? || (user.fund_manager? && hierarchy?)
  end

  private def hierarchy?
    record.hierarchy.is_a?(Programme) || record.hierarchy.is_a?(Fund)
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        funds = Fund.where(organisation_id: user.organisation)
        scope.where(hierarchy: funds)
        programmes = Programme.where(fund_id: funds)
        scope.where(hierarchy: [funds + programmes])
      end
    end
  end
end
