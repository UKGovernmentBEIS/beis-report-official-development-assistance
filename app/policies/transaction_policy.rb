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
        # TODO: when we add other hierarchy types, include them here somehow!
        organisations = user.organisation_ids
        funds = Fund.where(organisation_id: organisations)
        scope.where(hierarchy_id: funds)
      end
    end
  end
end
