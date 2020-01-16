class ProgrammePolicy < ApplicationPolicy
  def index?
    user.administrator? || user.fund_manager?
  end

  def show?
    user.administrator? || user.fund_manager?
  end

  def create?
    user.administrator? || user.fund_manager?
  end

  def update?
    user.administrator? || user.fund_manager?
  end

  def destroy?
    user.administrator? || user.fund_manager?
  end

  class Scope < Scope
    def resolve
      if user.administrator? || user.fund_manager?
        scope.all
      else
        scope.none
      end
    end
  end
end
