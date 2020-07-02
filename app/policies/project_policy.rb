class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    !beis_user?
  end

  def update?
    !beis_user?
  end

  def destroy?
    false
  end

  def download?
    beis_user?
  end

  def redact_from_iati?
    beis_user?
  end

  class Scope < Scope
    def resolve
      if user.organisation.service_owner?
        scope.all
      else
        scope.where(organisation: user.organisation)
      end
    end
  end
end
