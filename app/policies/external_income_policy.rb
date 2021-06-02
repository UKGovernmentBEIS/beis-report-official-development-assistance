class ExternalIncomePolicy < ApplicationPolicy
  def create?
    Pundit.policy(user, record.activity).update?
  end

  def update?
    create?
  end

  def destroy?
    update?
  end
end
