class UserPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    user.administrator? || user.fund_manager?
  end

  def update?
    user.administrator? || user.fund_manager?
  end
end
