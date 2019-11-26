class FundPolicy < ApplicationPolicy
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
        scope.where(organisation: [user.organisations])
      end
    end
  end
end
