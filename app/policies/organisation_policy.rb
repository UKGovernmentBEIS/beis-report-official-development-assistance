class OrganisationPolicy < ApplicationPolicy
  def index?
    user.administrator?
  end

  def show?
    user.administrator? || associated_user?
  end

  def create?
    user.administrator?
  end

  def update?
    user.administrator? || associated_user?
  end

  def destroy?
    user.administrator?
  end

  private def associated_user?
    user.organisation.eql?(record)
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        scope.where(id: user.organisation_id)
      end
    end
  end
end
