class FundPolicy < ApplicationPolicy
  def index?
    user.administrator? || user.organisations.include?(@record.organisation)
  end

  def show?
    user.administrator? || user.organisations.include?(@record.organisation)
  end

  def create?
    user.administrator?
  end

  def update?
    user.administrator?
  end

  def destroy?
    user.administrator?
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        scope.where(organisation: [user.organisations])
      end
    end
  end
end
