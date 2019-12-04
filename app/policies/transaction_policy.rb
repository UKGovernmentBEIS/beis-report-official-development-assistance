class TransactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    true
  end

  def destroy?
    true
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        organisations = user.organisation_ids
        funds = Fund.where(organisation_id: organisations)
        scope.where(fund_id: funds)
      end
    end
  end
end
