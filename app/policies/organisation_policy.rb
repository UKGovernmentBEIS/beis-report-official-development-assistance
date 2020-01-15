class OrganisationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator? || user.fund_manager? || associated_user?
  end

  def create?
    user.administrator? || user.fund_manager?
  end

  def update?
    user.administrator? || user.fund_manager? || associated_user?
  end

  def destroy?
    user.administrator? || user.fund_manager?
  end

  private def associated_user?
    user.organisation.eql?(record)
  end

  class Scope < Scope
    def resolve
      if user.administrator? || user.fund_manager?
        scope.all
      else
        scope.where(id: user.organisation_id)
      end
    end
  end
end
