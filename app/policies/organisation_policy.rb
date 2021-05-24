class OrganisationPolicy < ApplicationPolicy
  def index?
    beis_user?
  end

  def show?
    beis_user? || associated_user?
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

  private def associated_user?
    user.organisation.eql?(record)
  end
end
