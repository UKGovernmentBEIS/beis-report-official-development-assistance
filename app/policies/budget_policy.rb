class BudgetPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator?
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
        []
      end
    end
  end
end
