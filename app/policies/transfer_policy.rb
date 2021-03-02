class TransferPolicy < ApplicationPolicy
  def show?
    beis_user?
  end

  def create?
    beis_user?
  end

  def update?
    beis_user?
  end
end
