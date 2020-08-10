class SubmissionPolicy < ApplicationPolicy
  attr_reader :user, :record

  def index?
    true
  end

  def show?
    return true if beis_user?
    record.organisation == user.organisation
  end

  def create?
    beis_user?
  end

  def update?
    beis_user?
  end

  def download?
    return true if beis_user?
    record.organisation == user.organisation
  end

  def destroy?
    false
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
