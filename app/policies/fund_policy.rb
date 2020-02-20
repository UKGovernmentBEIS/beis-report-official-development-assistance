class FundPolicy < ApplicationPolicy
  def index?
    beis_user?
  end

  def show?
    beis_user?
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
      if user.organisation.service_owner?
        scope.all
      else
        scope.none
      end
    end
  end
end
