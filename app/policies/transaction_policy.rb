class TransactionPolicy < ApplicationPolicy
  def create?
    Pundit.policy!(user, record.parent_activity).create? && !!associated_submission&.active?
  end

  def update?
    Pundit.policy!(user, record.parent_activity).update? && !!associated_submission&.active?
  end

  def destroy?
    Pundit.policy!(user, record.parent_activity).destroy?
  end

  private

  def associated_submission
    parent_activity = record.parent_activity
    organisation = parent_activity.organisation
    fund = parent_activity.associated_fund
    Submission.find_by(organisation: organisation, fund: fund)
  end
end
