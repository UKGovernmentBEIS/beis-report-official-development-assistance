class ProgrammePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    beis_user?
  end

  def update?
    beis_user?
  end

  def destroy?
    beis_user?
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
