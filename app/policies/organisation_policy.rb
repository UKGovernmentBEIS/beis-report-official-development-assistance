class OrganisationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.administrator? || user.organisations.include?(@record)
  end

  def update?
    user.administrator? || user.organisations.include?(@record)
  end

  class Scope < Scope
    def resolve
      if user.administrator?
        scope.all
      else
        scope.where(id: user.organisation_ids)
      end
    end
  end
end
