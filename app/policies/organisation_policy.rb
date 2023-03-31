class OrganisationPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    beis_user? || associated_user?
  end

  def bulk_upload?
    beis_user?
  end

  def create?
    beis_user?
  end

  def update?
    beis_user? || associated_user?
  end

  def destroy?
    beis_user?
  end

  def download?
    return false if record.service_owner?
    beis_user?
  end

  class Scope < Scope
    def resolve
      return scope.all if user.service_owner?

      Organisation.implementing
    end
  end

  private def associated_user?
    user.organisation.eql?(record)
  end
end
