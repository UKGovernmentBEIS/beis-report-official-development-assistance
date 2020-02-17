class UserPolicy < ApplicationPolicy
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

  private

  def beis_user?
    user.organisation.service_owner?
  end
end
