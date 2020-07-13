class TransactionPolicy < ApplicationPolicy
  def create?
    Pundit.policy!(user, record.parent_activity).create?
  end

  def update?
    Pundit.policy!(user, record.parent_activity).update?
  end

  def destroy?
    Pundit.policy!(user, record.parent_activity).destroy?
  end
end
